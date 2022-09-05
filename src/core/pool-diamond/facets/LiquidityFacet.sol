// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { LibReentrancyGuard } from "../libraries/LibReentrancyGuard.sol";
import { LibPoolV1 } from "../libraries/LibPoolV1.sol";

import { GetterFacetInterface } from "../interfaces/GetterFacetInterface.sol";
import { FundingRateFacetInterface } from "../interfaces/FundingRateFacetInterface.sol";
import { LiquidityFacetInterface } from "../interfaces/LiquidityFacetInterface.sol";

contract LiquidityFacet is LiquidityFacetInterface {
  error LiquidityFacet_BadAmount();
  error LiquidityFacet_BadToken();
  error LiquidityFacet_InsufficientLiquidityMint();

  uint256 internal constant PRICE_PRECISION = 10**30;
  uint256 internal constant BPS = 10000;
  uint256 internal constant USD_DECIMALS = 18;

  event AddLiquidity(
    address account,
    address token,
    uint256 amount,
    uint256 aum,
    uint256 supply,
    uint256 usdDebt,
    uint256 mintAmount
  );
  event CollectSwapFee(address token, uint256 feeUsd, uint256 fee);
  event ExitPool(
    address account,
    address token,
    uint256 usdAmount,
    uint256 amountOut,
    uint256 burnFeeBps
  );
  event JoinPool(
    address account,
    address token,
    uint256 amount,
    uint256 usdDebt,
    uint256 mintFeeBps
  );
  event RemoveLiquidity(
    address account,
    address tokenOut,
    uint256 liquidity,
    uint256 aum,
    uint256 supply,
    uint256 usdDebt,
    uint256 amountOut
  );

  function _collectSwapFee(
    address token,
    uint256 tokenPriceUsd,
    uint256 amount,
    uint256 feeBps
  ) internal returns (uint256) {
    // Load diamond storage
    LibPoolV1.PoolV1DiamondStorage storage poolV1ds = LibPoolV1
      .poolV1DiamondStorage();

    uint256 amountAfterFee = (amount * (BPS - feeBps)) / BPS;
    uint256 fee = amount - amountAfterFee;

    poolV1ds.feeReserveOf[token] += fee;

    emit CollectSwapFee(token, fee * tokenPriceUsd, fee);

    return amountAfterFee;
  }

  function addLiquidity(
    address account,
    address token,
    address receiver
  ) external returns (uint256) {
    LibReentrancyGuard.lock();
    LibPoolV1.allowed(account);

    // LOAD diamond storage
    LibPoolV1.PoolV1DiamondStorage storage poolV1ds = LibPoolV1
      .poolV1DiamondStorage();

    // Pull tokens
    uint256 amount = LibPoolV1.pullTokens(token);

    // Check
    if (!poolV1ds.config.isAcceptToken(token)) revert LiquidityFacet_BadToken();
    if (amount == 0) revert LiquidityFacet_BadAmount();

    uint256 aum = GetterFacetInterface(address(this)).getAumE18(true);
    uint256 lpSupply = poolV1ds.plp.totalSupply();

    uint256 usdDebt = _join(token, amount, receiver);
    uint256 mintAmount = aum == 0 ? usdDebt : (usdDebt * lpSupply) / aum;

    poolV1ds.plp.mint(receiver, mintAmount);

    poolV1ds.lastAddLiquidityAtOf[account] = block.timestamp;

    emit AddLiquidity(
      account,
      token,
      amount,
      aum,
      lpSupply,
      usdDebt,
      mintAmount
    );

    return mintAmount;
  }

  function _join(
    address token,
    uint256 amount,
    address receiver
  ) internal returns (uint256) {
    // LOAD diamond storage
    LibPoolV1.PoolV1DiamondStorage storage poolV1ds = LibPoolV1
      .poolV1DiamondStorage();

    FundingRateFacetInterface(address(this)).updateFundingRate(token, token);

    uint256 price = poolV1ds.oracle.getMinPrice(token);

    uint256 tokenValueUsd = (amount * price) / PRICE_PRECISION;
    uint8 tokenDecimals = poolV1ds.config.getTokenDecimalsOf(token);
    tokenValueUsd = LibPoolV1.convertTokenDecimals(
      tokenDecimals,
      USD_DECIMALS,
      tokenValueUsd
    );
    if (tokenValueUsd == 0) revert LiquidityFacet_InsufficientLiquidityMint();

    uint256 feeBps = GetterFacetInterface(address(this)).getAddLiquidityFeeBps(
      token,
      tokenValueUsd
    );
    uint256 amountAfterDepositFee = _collectSwapFee(
      token,
      price,
      amount,
      feeBps
    );
    uint256 usdDebt = LibPoolV1.convertTokenDecimals(
      tokenDecimals,
      USD_DECIMALS,
      (amountAfterDepositFee * price) / PRICE_PRECISION
    );

    LibPoolV1.increaseUsdDebt(token, usdDebt);
    LibPoolV1.increasePoolLiquidity(token, amountAfterDepositFee);

    poolV1ds.totalUsdDebt += usdDebt;

    emit JoinPool(receiver, token, amount, usdDebt, feeBps);

    LibReentrancyGuard.unlock();

    return usdDebt;
  }
}
