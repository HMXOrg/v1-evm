// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import { DSTest } from "./DSTest.sol";

import { VM } from "../utils/VM.sol";
import { console } from "../utils/console.sol";
import { math } from "../utils/math.sol";

import { Constants as CoreConstants } from "../../core/Constants.sol";

import { MockErc20 } from "../mocks/MockERC20.sol";
import { MockWNative } from "../mocks/MockWNative.sol";
import { MockChainlinkPriceFeed } from "../mocks/MockChainlinkPriceFeed.sol";

import { PoolOracle } from "../../core/PoolOracle.sol";
import { PoolConfig } from "../../core/PoolConfig.sol";
import { PoolMath } from "../../core/PoolMath.sol";
import { PLP } from "../../tokens/PLP.sol";
import { P88 } from "../../tokens/P88.sol";
import { EsP88 } from "../../tokens/EsP88.sol";
import { DragonPoint } from "../../tokens/DragonPoint.sol";
import { Pool } from "../../core/Pool.sol";
import { PLPStaking } from "../../staking/PLPStaking.sol";
import { DragonStaking } from "../../staking/DragonStaking.sol";
import { FeedableRewarder } from "../../staking/FeedableRewarder.sol";
import { AdHocMintRewarder } from "../../staking/AdHocMintRewarder.sol";
import { WFeedableRewarder } from "../../staking/WFeedableRewarder.sol";
import { RewardDistributor } from "../../staking/RewardDistributor.sol";
import { Compounder } from "../../staking/Compounder.sol";
import { Vester } from "../../vesting/Vester.sol";
import { ProxyAdmin } from "../interfaces/ProxyAdmin.sol";
import { Lockdrop } from "../../lockdrop/Lockdrop.sol";
import { LockdropGateway } from "../../lockdrop/LockdropGateway.sol";
import { LockdropConfig } from "../../lockdrop/LockdropConfig.sol";

// solhint-disable const-name-snakecase
// solhint-disable no-inline-assembly
contract BaseTest is DSTest, CoreConstants {
  struct PoolConfigConstructorParams {
    uint64 fundingInterval;
    uint64 mintBurnFeeBps;
    uint64 taxBps;
    uint64 stableFundingRateFactor;
    uint64 fundingRateFactor;
    uint64 liquidityCoolDownPeriod;
  }

  VM internal constant vm = VM(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

  // Note: Avoid using address(1) as it is reserved for Ecrecover.
  // ref: https://ethereum.stackexchange.com/questions/89447/how-does-ecrecover-get-compiled
  // One pitfall is that, when transferring native token to address(1),
  // it will revert with PRECOMPILE::ecrecover.
  address internal constant ALICE = address(5);
  address internal constant BOB = address(2);
  address internal constant CAT = address(3);
  address internal constant DAVE = address(4);

  MockErc20 internal matic;
  MockErc20 internal weth;
  MockErc20 internal wbtc;
  MockErc20 internal dai;
  MockErc20 internal usdc;

  MockChainlinkPriceFeed internal maticPriceFeed;
  MockChainlinkPriceFeed internal wethPriceFeed;
  MockChainlinkPriceFeed internal wbtcPriceFeed;
  MockChainlinkPriceFeed internal daiPriceFeed;
  MockChainlinkPriceFeed internal usdcPriceFeed;

  ProxyAdmin internal proxyAdmin;

  constructor() {
    matic = deployMockErc20("Matic Token", "MATIC", 18);
    weth = deployMockErc20("Wrapped Ethereum", "WETH", 18);
    wbtc = deployMockErc20("Wrapped Bitcoin", "WBTC", 8);
    dai = deployMockErc20("DAI Stablecoin", "DAI", 18);
    usdc = deployMockErc20("USD Coin", "USDC", 6);

    maticPriceFeed = deployMockChainlinkPriceFeed();
    wethPriceFeed = deployMockChainlinkPriceFeed();
    wbtcPriceFeed = deployMockChainlinkPriceFeed();
    daiPriceFeed = deployMockChainlinkPriceFeed();
    usdcPriceFeed = deployMockChainlinkPriceFeed();

    proxyAdmin = _setupProxyAdmin();
  }

  function _setupProxyAdmin() internal returns (ProxyAdmin) {
    bytes memory _bytecode = abi.encodePacked(
      vm.getCode("./out/ProxyAdmin.sol/ProxyAdmin.json")
    );
    address _address;
    assembly {
      _address := create(0, add(_bytecode, 0x20), mload(_bytecode))
    }
    return ProxyAdmin(address(_address));
  }

  function buildDefaultSetPriceFeedInput()
    internal
    view
    returns (address[] memory, PoolOracle.PriceFeedInfo[] memory)
  {
    address[] memory tokens = new address[](5);
    tokens[0] = address(matic);
    tokens[1] = address(weth);
    tokens[2] = address(wbtc);
    tokens[3] = address(dai);
    tokens[4] = address(usdc);

    PoolOracle.PriceFeedInfo[]
      memory priceFeedInfo = new PoolOracle.PriceFeedInfo[](5);
    priceFeedInfo[0] = PoolOracle.PriceFeedInfo({
      priceFeed: maticPriceFeed,
      decimals: 8,
      spreadBps: 0,
      isStrictStable: false
    });
    priceFeedInfo[1] = PoolOracle.PriceFeedInfo({
      priceFeed: wethPriceFeed,
      decimals: 8,
      spreadBps: 0,
      isStrictStable: false
    });
    priceFeedInfo[2] = PoolOracle.PriceFeedInfo({
      priceFeed: wbtcPriceFeed,
      decimals: 8,
      spreadBps: 0,
      isStrictStable: false
    });
    priceFeedInfo[3] = PoolOracle.PriceFeedInfo({
      priceFeed: daiPriceFeed,
      decimals: 8,
      spreadBps: 0,
      isStrictStable: false
    });
    priceFeedInfo[4] = PoolOracle.PriceFeedInfo({
      priceFeed: usdcPriceFeed,
      decimals: 8,
      spreadBps: 0,
      isStrictStable: true
    });

    return (tokens, priceFeedInfo);
  }

  function _setupUpgradeable(
    bytes memory _logicBytecode,
    bytes memory _initializer
  ) internal returns (address) {
    bytes memory _proxyBytecode = abi.encodePacked(
      vm.getCode(
        "./out/TransparentUpgradeableProxy.sol/TransparentUpgradeableProxy.json"
      )
    );

    address _logic;
    assembly {
      _logic := create(0, add(_logicBytecode, 0x20), mload(_logicBytecode))
    }

    _proxyBytecode = abi.encodePacked(
      _proxyBytecode,
      abi.encode(_logic, address(proxyAdmin), _initializer)
    );

    address _proxy;
    assembly {
      _proxy := create(0, add(_proxyBytecode, 0x20), mload(_proxyBytecode))
      if iszero(extcodesize(_proxy)) {
        revert(0, 0)
      }
    }

    return _proxy;
  }

  function deployMockWNative() internal returns (MockWNative) {
    return new MockWNative();
  }

  function deployMockErc20(
    string memory name,
    string memory symbol,
    uint8 decimals
  ) internal returns (MockErc20) {
    return new MockErc20(name, symbol, decimals);
  }

  function deployMockChainlinkPriceFeed()
    internal
    returns (MockChainlinkPriceFeed)
  {
    return new MockChainlinkPriceFeed();
  }

  function deployPLP() internal returns (PLP) {
    return new PLP();
  }

  function deployP88() internal returns (P88) {
    return new P88();
  }

  function deployEsP88() internal returns (EsP88) {
    return new EsP88();
  }

  function deployDragonPoint() internal returns (DragonPoint) {
    return new DragonPoint();
  }

  function deployPoolOracle(uint80 roundDepth) internal returns (PoolOracle) {
    bytes memory _logicBytecode = abi.encodePacked(
      vm.getCode("./out/PoolOracle.sol/PoolOracle.json")
    );
    bytes memory _initializer = abi.encodeWithSelector(
      bytes4(keccak256("initialize(uint80)")),
      roundDepth
    );
    address _proxy = _setupUpgradeable(_logicBytecode, _initializer);
    return PoolOracle(payable(_proxy));
  }

  function deployPoolConfig(PoolConfigConstructorParams memory params)
    internal
    returns (PoolConfig)
  {
    bytes memory _logicBytecode = abi.encodePacked(
      vm.getCode("./out/PoolConfig.sol/PoolConfig.json")
    );
    bytes memory _initializer = abi.encodeWithSelector(
      bytes4(
        keccak256("initialize(uint64,uint64,uint64,uint64,uint64,uint64)")
      ),
      params.fundingInterval,
      params.mintBurnFeeBps,
      params.taxBps,
      params.stableFundingRateFactor,
      params.fundingRateFactor,
      params.liquidityCoolDownPeriod
    );
    address _proxy = _setupUpgradeable(_logicBytecode, _initializer);
    return PoolConfig(payable(_proxy));
  }

  function deployPoolMath() internal returns (PoolMath) {
    return new PoolMath();
  }

  function deployFullPool(
    PoolConfigConstructorParams memory poolConfigConstructorParams
  )
    internal
    returns (
      PoolOracle,
      PoolConfig,
      PoolMath,
      Pool
    )
  {
    // Deploy Pool's dependencies
    PoolOracle poolOracle = deployPoolOracle(3);
    PoolConfig poolConfig = deployPoolConfig(poolConfigConstructorParams);
    PoolMath poolMath = deployPoolMath();
    PLP plp = deployPLP();

    // Deploy Pool
    bytes memory _logicBytecode = abi.encodePacked(
      vm.getCode("./out/Pool.sol/Pool.json")
    );
    bytes memory _initializer = abi.encodeWithSelector(
      bytes4(keccak256("initialize(address,address,address,address)")),
      address(plp),
      address(poolConfig),
      address(poolMath),
      address(poolOracle)
    );
    address _proxy = _setupUpgradeable(_logicBytecode, _initializer);
    Pool pool = Pool(payable(_proxy));

    // Config
    plp.setMinter(address(pool), true);

    return (poolOracle, poolConfig, poolMath, pool);
  }

  function deployPLPStaking() internal returns (PLPStaking) {
    bytes memory _logicBytecode = abi.encodePacked(
      vm.getCode("./out/PLPStaking.sol/PLPStaking.json")
    );
    bytes memory _initializer = abi.encodeWithSelector(
      bytes4(keccak256("initialize()"))
    );
    address _proxy = _setupUpgradeable(_logicBytecode, _initializer);
    return PLPStaking(payable(_proxy));
  }

  function deployDragonStaking(address dragonPointToken)
    internal
    returns (DragonStaking)
  {
    bytes memory _logicBytecode = abi.encodePacked(
      vm.getCode("./out/DragonStaking.sol/DragonStaking.json")
    );
    bytes memory _initializer = abi.encodeWithSelector(
      bytes4(keccak256("initialize(address)")),
      dragonPointToken
    );
    address _proxy = _setupUpgradeable(_logicBytecode, _initializer);
    return DragonStaking(payable(_proxy));
  }

  function deployFeedableRewarder(
    string memory name,
    address rewardToken,
    address staking
  ) internal returns (FeedableRewarder) {
    bytes memory _logicBytecode = abi.encodePacked(
      vm.getCode("./out/FeedableRewarder.sol/FeedableRewarder.json")
    );
    bytes memory _initializer = abi.encodeWithSelector(
      bytes4(keccak256("initialize(string,address,address)")),
      name,
      rewardToken,
      staking
    );
    address _proxy = _setupUpgradeable(_logicBytecode, _initializer);
    return FeedableRewarder(payable(_proxy));
  }

  function deployAdHocMintRewarder(
    string memory name,
    address rewardToken,
    address staking
  ) internal returns (AdHocMintRewarder) {
    bytes memory _logicBytecode = abi.encodePacked(
      vm.getCode("./out/AdHocMintRewarder.sol/AdHocMintRewarder.json")
    );
    bytes memory _initializer = abi.encodeWithSelector(
      bytes4(keccak256("initialize(string,address,address)")),
      name,
      rewardToken,
      staking
    );
    address _proxy = _setupUpgradeable(_logicBytecode, _initializer);
    return AdHocMintRewarder(payable(_proxy));
  }

  function deployWFeedableRewarder(
    string memory name,
    address rewardToken,
    address staking
  ) internal returns (WFeedableRewarder) {
    bytes memory _logicBytecode = abi.encodePacked(
      vm.getCode("./out/WFeedableRewarder.sol/WFeedableRewarder.json")
    );
    bytes memory _initializer = abi.encodeWithSelector(
      bytes4(keccak256("initialize(string,address,address)")),
      name,
      rewardToken,
      staking
    );
    address _proxy = _setupUpgradeable(_logicBytecode, _initializer);
    return WFeedableRewarder(payable(_proxy));
  }

  function deployCompounder(
    address dp,
    address compoundPool,
    address[] memory tokens,
    bool[] memory isCompoundTokens
  ) internal returns (Compounder) {
    bytes memory _logicBytecode = abi.encodePacked(
      vm.getCode("./out/Compounder.sol/Compounder.json")
    );
    bytes memory _initializer = abi.encodeWithSelector(
      bytes4(keccak256("initialize(address,address,address[],bool[])")),
      dp,
      compoundPool,
      tokens,
      isCompoundTokens
    );
    address _proxy = _setupUpgradeable(_logicBytecode, _initializer);
    return Compounder(payable(_proxy));
  }

  function deployVester(
    address esP88Address,
    address p88Address,
    address vestedEsp88DestinationAddress,
    address unusedEsp88DestinationAddress
  ) internal returns (Vester) {
    bytes memory _logicBytecode = abi.encodePacked(
      vm.getCode("./out/Vester.sol/Vester.json")
    );
    bytes memory _initializer = abi.encodeWithSelector(
      bytes4(keccak256("initialize(address,address,address,address)")),
      esP88Address,
      p88Address,
      vestedEsp88DestinationAddress,
      unusedEsp88DestinationAddress
    );
    address _proxy = _setupUpgradeable(_logicBytecode, _initializer);
    return Vester(payable(_proxy));
  }

  function deployRewardDistributor(
    address rewardToken,
    address pool,
    address feedableRewarder
  ) internal returns (RewardDistributor) {
    bytes memory _logicBytecode = abi.encodePacked(
      vm.getCode("./out/RewardDistributor.sol/RewardDistributor.json")
    );
    bytes memory _initializer = abi.encodeWithSelector(
      bytes4(keccak256("initialize(address,address,address)")),
      rewardToken,
      pool,
      feedableRewarder
    );
    address _proxy = _setupUpgradeable(_logicBytecode, _initializer);
    return RewardDistributor(payable(_proxy));
  }

  function deployLockdropConfig(
    uint256 startLockTimestamp,
    address plpStaking,
    address plpToken,
    address p88Token,
    address gatewayAddress
  ) internal returns (LockdropConfig) {
    bytes memory _logicBytecode = abi.encodePacked(
      vm.getCode("./out/LockdropConfig.sol/LockdropConfig.json")
    );
    bytes memory _initializer = abi.encodeWithSelector(
      bytes4(keccak256("initialize(uint256,address,address,address,address)")),
      startLockTimestamp,
      plpStaking,
      plpToken,
      p88Token,
      gatewayAddress
    );
    address _proxy = _setupUpgradeable(_logicBytecode, _initializer);
    return LockdropConfig(payable(_proxy));
  }

  function deployLockdrop(
    address lockdropToken_,
    address pool_,
    address lockdropConfig_,
    address[] memory rewardTokens_,
    address nativeTokenAddress_
  ) internal returns (Lockdrop) {
    bytes memory _logicBytecode = abi.encodePacked(
      vm.getCode("./out/Lockdrop.sol/Lockdrop.json")
    );
    bytes memory _initializer = abi.encodeWithSelector(
      bytes4(
        keccak256("initialize(address,address,address,address[],address)")
      ),
      lockdropToken_,
      pool_,
      lockdropConfig_,
      rewardTokens_,
      nativeTokenAddress_
    );
    address _proxy = _setupUpgradeable(_logicBytecode, _initializer);
    return Lockdrop(payable(_proxy));
  }

  function deployLockdropGateway(address plpToken, address plpStaking)
    internal
    returns (LockdropGateway)
  {
    bytes memory _logicBytecode = abi.encodePacked(
      vm.getCode("./out/LockdropGateway.sol/LockdropGateway.json")
    );
    bytes memory _initializer = abi.encodeWithSelector(
      bytes4(keccak256("initialize(address,address)")),
      plpToken,
      plpStaking
    );
    address _proxy = _setupUpgradeable(_logicBytecode, _initializer);
    return LockdropGateway(payable(_proxy));
  }
}
