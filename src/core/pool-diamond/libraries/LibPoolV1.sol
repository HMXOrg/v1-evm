// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { PLP } from "../../../tokens/PLP.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { PoolOracle } from "../../PoolOracle.sol";
import { Constants } from "../../Constants.sol";
import { LibPoolConfigV1 } from "./LibPoolConfigV1.sol";

library LibPoolV1 {
  using SafeERC20 for IERC20;

  error LibPoolV1_BadSubAccountId();
  error LibPoolV1_Forbidden();
  error LibPoolV1_LiquidityMismatch();
  error LibPoolV1_InsufficientLiquidity();
  error LibPoolV1_OverUsdDebtCeiling();
  error LibPoolV1_OverShortCeiling();

  // -------------
  //   Constants
  // -------------
  // POOL_V1_STORAGE_POSITION = keccak256("com.perp88.poolv1.diamond.storage")
  bytes32 internal constant POOL_V1_STORAGE_POSITION =
    0x314015ac733c0279c4c55e1f61d17cd364070d3fa6bee7b638d441b70d2114b1;

  enum MinMax {
    MIN,
    MAX
  }

  // -------------
  //    Storage
  // -------------
  struct Position {
    address primaryAccount;
    uint256 size;
    uint256 collateral; // collateral value in USD
    uint256 averagePrice;
    uint256 entryFundingRate;
    uint256 reserveAmount;
    int256 realizedPnl;
    uint256 lastIncreasedTime;
  }

  struct PoolV1DiamondStorage {
    // Dependent contracts
    PLP plp;
    PoolOracle oracle;
    // Liquidity
    mapping(address => uint256) totalOf;
    mapping(address => uint256) liquidityOf;
    mapping(address => uint256) reservedOf;
    mapping(address => uint256) sumFundingRateOf;
    mapping(address => uint256) lastFundingTimeOf;
    // Short
    mapping(address => uint256) shortSizeOf;
    mapping(address => uint256) shortAveragePriceOf;
    // Fee
    mapping(address => uint256) feeReserveOf;
    // Debt
    uint256 totalUsdDebt;
    mapping(address => uint256) usdDebtOf;
    mapping(address => uint256) guaranteedUsdOf;
    // AUM
    uint256 additionalAum;
    uint256 discountedAum;
    // Position
    mapping(bytes32 => Position) positions;
    mapping(address => mapping(address => bool)) approvedPlugins;
  }

  // -----------
  //   Events
  // -----------
  event DecreaseGuaranteedUsd(address token, uint256 amount);
  event DecreasePoolLiquidity(address token, uint256 amount);
  event DecreaseUsdDebt(address token, uint256 amount);
  event DecreaseReserved(address token, uint256 amount);
  event DecreaseShortSize(address token, uint256 amount);
  event IncreaseGuaranteedUsd(address token, uint256 amount);
  event IncreasePoolLiquidity(address token, uint256 amount);
  event IncreaseUsdDebt(address token, uint256 amount);
  event IncreaseReserved(address token, uint256 amount);
  event IncreaseShortSize(address token, uint256 amount);
  event SetPoolConfig(address prevPoolConfig, address newPoolConfig);
  event SetPoolOracle(address prevPoolOracle, address newPoolOracle);

  function poolV1DiamondStorage()
    internal
    pure
    returns (PoolV1DiamondStorage storage poolV1ds)
  {
    assembly {
      poolV1ds.slot := POOL_V1_STORAGE_POSITION
    }
  }

  function setPLP(PLP newPLP) internal {
    PoolV1DiamondStorage storage poolV1ds = poolV1DiamondStorage();
    poolV1ds.plp = newPLP;
  }

  function setPoolOracle(PoolOracle newOracle) internal {
    PoolV1DiamondStorage storage poolV1ds = poolV1DiamondStorage();
    emit SetPoolOracle(address(poolV1ds.oracle), address(newOracle));
    poolV1ds.oracle = newOracle;
  }

  // --------------
  // Access Control
  // --------------
  function allowed(address account) internal view {
    PoolV1DiamondStorage storage poolV1ds = poolV1DiamondStorage();
    // Load PoolConfigV1 diamond storage
    LibPoolConfigV1.PoolConfigV1DiamondStorage
      storage poolConfigds = LibPoolConfigV1.poolConfigV1DiamondStorage();

    if (account != msg.sender && poolConfigds.router != msg.sender) {
      if (!poolV1ds.approvedPlugins[account][msg.sender])
        revert LibPoolV1_Forbidden();
    }
  }

  // -----------------
  // Queries functions
  // -----------------
  function getPositionId(
    address account,
    address collateralToken,
    address indexToken,
    bool isLong
  ) internal pure returns (bytes32) {
    return
      keccak256(abi.encodePacked(account, collateralToken, indexToken, isLong));
  }

  function getSubAccount(address primary, uint256 subAccountId)
    internal
    pure
    returns (address)
  {
    if (subAccountId > 255) revert LibPoolV1_BadSubAccountId();
    return address(uint160(primary) ^ uint160(subAccountId));
  }

  // ------------------------------
  // Liquidity alteration functions
  // ------------------------------

  function increasePoolLiquidity(address token, uint256 amount) internal {
    PoolV1DiamondStorage storage poolV1ds = poolV1DiamondStorage();

    poolV1ds.liquidityOf[token] += amount;
    if (IERC20(token).balanceOf(address(this)) < poolV1ds.liquidityOf[token])
      revert LibPoolV1_LiquidityMismatch();
    emit IncreasePoolLiquidity(token, amount);
  }

  function decreasePoolLiquidity(address token, uint256 amount) internal {
    PoolV1DiamondStorage storage poolV1ds = poolV1DiamondStorage();

    poolV1ds.liquidityOf[token] -= amount;
    if (poolV1ds.liquidityOf[token] < poolV1ds.reservedOf[token])
      revert LibPoolV1_InsufficientLiquidity();
    emit DecreasePoolLiquidity(token, amount);
  }

  function increaseUsdDebt(address token, uint256 amount) internal {
    PoolV1DiamondStorage storage poolV1ds = poolV1DiamondStorage();

    poolV1ds.usdDebtOf[token] += amount;

    // SLOAD
    uint256 newUsdDebt = poolV1ds.usdDebtOf[token];
    uint256 usdDebtCeiling = LibPoolConfigV1.getTokenUsdDebtCeilingOf(token);

    if (usdDebtCeiling != 0) {
      if (newUsdDebt > usdDebtCeiling) revert LibPoolV1_OverUsdDebtCeiling();
    }

    emit IncreaseUsdDebt(token, amount);
  }

  function decreaseUsdDebt(address token, uint256 amount) internal {
    PoolV1DiamondStorage storage poolV1ds = poolV1DiamondStorage();

    uint256 usdDebt = poolV1ds.usdDebtOf[token];
    if (usdDebt <= amount) {
      poolV1ds.usdDebtOf[token] = 0;
      emit DecreaseUsdDebt(token, usdDebt);
      return;
    }

    poolV1ds.usdDebtOf[token] = usdDebt - amount;

    emit DecreaseUsdDebt(token, amount);
  }

  function increaseReserved(address token, uint256 amount) internal {
    PoolV1DiamondStorage storage poolV1ds = poolV1DiamondStorage();

    poolV1ds.reservedOf[token] += amount;
    if (poolV1ds.reservedOf[token] > poolV1ds.liquidityOf[token])
      revert LibPoolV1_InsufficientLiquidity();
    emit IncreaseReserved(token, amount);
  }

  function decreaseReserved(address token, uint256 amount) internal {
    PoolV1DiamondStorage storage poolV1ds = poolV1DiamondStorage();

    poolV1ds.reservedOf[token] -= amount;
    emit DecreaseReserved(token, amount);
  }

  function increaseGuaranteedUsd(address token, uint256 amountUsd) internal {
    PoolV1DiamondStorage storage poolV1ds = poolV1DiamondStorage();

    poolV1ds.guaranteedUsdOf[token] += amountUsd;
    emit IncreaseGuaranteedUsd(token, amountUsd);
  }

  function decreaseGuaranteedUsd(address token, uint256 amountUsd) internal {
    PoolV1DiamondStorage storage poolV1ds = poolV1DiamondStorage();

    poolV1ds.guaranteedUsdOf[token] -= amountUsd;
    emit DecreaseGuaranteedUsd(token, amountUsd);
  }

  function increaseShortSize(address token, uint256 amountUsd) internal {
    PoolV1DiamondStorage storage poolV1ds = poolV1DiamondStorage();

    // SLOAD
    uint256 shortCeiling = LibPoolConfigV1.getTokenShortCeilingOf(token);
    poolV1ds.shortSizeOf[token] += amountUsd;

    if (shortCeiling != 0) {
      if (poolV1ds.shortSizeOf[token] > shortCeiling)
        revert LibPoolV1_OverShortCeiling();
    }

    emit IncreaseShortSize(token, amountUsd);
  }

  function decreaseShortSize(address token, uint256 amountUsd) internal {
    PoolV1DiamondStorage storage poolV1ds = poolV1DiamondStorage();

    uint256 shortSize = poolV1ds.shortSizeOf[token];
    if (amountUsd > shortSize) {
      poolV1ds.shortSizeOf[token] = 0;
      return;
    }

    poolV1ds.shortSizeOf[token] -= amountUsd;

    emit DecreaseShortSize(token, amountUsd);
  }

  /// ---------------------------
  /// ERC20 interaction functions
  /// ---------------------------

  function pullTokens(address token) internal returns (uint256) {
    PoolV1DiamondStorage storage poolV1ds = poolV1DiamondStorage();

    uint256 prevBalance = poolV1ds.totalOf[token];
    uint256 nextBalance = IERC20(token).balanceOf(address(this));

    poolV1ds.totalOf[token] = nextBalance;

    return nextBalance - prevBalance;
  }

  function pushTokens(
    address token,
    address to,
    uint256 amount
  ) internal {
    PoolV1DiamondStorage storage poolV1ds = poolV1DiamondStorage();

    IERC20(token).safeTransfer(to, amount);
    poolV1ds.totalOf[token] = IERC20(token).balanceOf(address(this));
  }

  /// --------------------
  /// Conversion functions
  /// --------------------
  function convertTokenDecimals(
    uint256 fromTokenDecimals,
    uint256 toTokenDecimals,
    uint256 amount
  ) internal pure returns (uint256) {
    return (amount * 10**toTokenDecimals) / 10**fromTokenDecimals;
  }

  function convertUsde30ToTokens(
    address token,
    uint256 amountUsd,
    bool isUseMaxPrice
  ) internal view returns (uint256) {
    if (amountUsd == 0) return 0;

    // Load PoolV1 diamond storage
    PoolV1DiamondStorage storage poolV1ds = poolV1DiamondStorage();

    return
      (amountUsd * (10**LibPoolConfigV1.getTokenDecimalsOf(token))) /
      poolV1ds.oracle.getPrice(token, isUseMaxPrice);
  }

  function convertTokensToUsde30(
    address token,
    uint256 amountTokens,
    bool isUseMaxPrice
  ) internal view returns (uint256) {
    if (amountTokens == 0) return 0;

    // Load PoolV1 diamond storage
    PoolV1DiamondStorage storage poolV1ds = poolV1DiamondStorage();

    return
      (amountTokens * poolV1ds.oracle.getPrice(token, isUseMaxPrice)) /
      (10**LibPoolConfigV1.getTokenDecimalsOf(token));
  }
}
