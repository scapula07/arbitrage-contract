//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;
pragma abicoder v2;


import "@uniswap/v3-core/contracts/interfaces/pool/IUniswapV3PoolImmutables.sol";
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import  '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import "@uniswap/v3-core/contracts/interfaces/IERC20Minimal.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

contract ArbitrageBot {
  string public name;
  ISwapRouter public swapRouter;
  address public Router2;
 


    uint constant deadline = 20 minutes; // transaction deadline
   
    string base;
    string assest;
    address public owner;
    uint profit;

    
  // For this example, we will set the pool fee to 0.3%.
  uint24 public constant poolFee = 3000;

  
     event TradeSucces(
          string assest,
          string base,
          uint profit,
          bool success
     );


      mapping(address => uint) _balance;
      
     


  constructor( ISwapRouter _Router1, address _Router2) {
      swapRouter = _Router1;
      Router2 = _Router2;
      name="Arbitrage Bot";
     
      owner=msg.sender;

  }
   modifier onlyOwner(){
      require(msg.sender==owner,"");
          _;
     }

   function getAmountOutMin( address _router,address _token1, address _token2, uint256 _amount)  public view returns (uint256) {
	      	address[] memory path;
	      	path = new address[](2);
	      	path[0] = _token1;
	      	path[1] = _token2;
	      	uint256[] memory amountOutMins = IUniswapV2Router02(address(_router)).getAmountsOut(_amount, path);
	      	
            return  amountOutMins[path.length -1];
             
      }

  function getSushiswapReserve(address _pairAddress) public view returns(uint, uint, uint){
      (uint reserve1,uint reserve2,uint time)=IUniswapV2Pair(address(_pairAddress)).getReserves();
     
      return (reserve1,reserve2,time);

  }

     // for uniswap
  function uniDAIWETHswapExactInputSingle(address _tokenIn, address _tokenOut) public  returns (uint256 amountOut) {
      uint _amountIn = IERC20Minimal(_tokenIn).balanceOf(address(this));

      // Transfer the specified amount of DAI to this contract.
     // TransferHelper.safeTransferFrom(_tokenIn, msg.sender, address(this), _amountIn);

      // Approve the router to spend DAI.
      TransferHelper.safeApprove(_tokenIn, address(swapRouter), _amountIn);
        IERC20Minimal(_tokenIn).allowance(address(this), address(swapRouter));
      // Naively set amountOutMinimum to 0. In production, use an oracle or other data source to choose a safer value for amountOutMinimum.
      // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
      ISwapRouter.ExactInputSingleParams memory params =
          ISwapRouter.ExactInputSingleParams({
              tokenIn: _tokenIn,
              tokenOut: _tokenOut,
              fee: poolFee,
              recipient: address(this),
              deadline: block.timestamp + deadline,
              amountIn:_amountIn,
              amountOutMinimum:0,
              sqrtPriceLimitX96: 0
          });

      // The call to `exactInputSingle` executes the swap.
      amountOut = swapRouter.exactInputSingle(params);
  }
   
    function uniWETHDAIswapExactInputSingle(address _tokenIn, address _tokenOut) public  returns (uint256 amountOut) {
      uint _amountIn = IERC20Minimal(_tokenIn).balanceOf(address(this));

      // Transfer the specified amount of DAI to this contract.
     // TransferHelper.safeTransferFrom(_tokenIn, msg.sender, address(this), _amountIn);

      // Approve the router to spend DAI.
      TransferHelper.safeApprove(_tokenIn, address(swapRouter), _amountIn);
        IERC20Minimal(_tokenIn).allowance(address(this), address(swapRouter));
      // Naively set amountOutMinimum to 0. In production, use an oracle or other data source to choose a safer value for amountOutMinimum.
      // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
      ISwapRouter.ExactInputSingleParams memory params =
          ISwapRouter.ExactInputSingleParams({
              tokenIn: _tokenIn,
              tokenOut: _tokenOut,
              fee: poolFee,
              recipient: address(this),
              deadline: block.timestamp + deadline,
              amountIn:_amountIn,
              amountOutMinimum:0,
              sqrtPriceLimitX96: 0
          });

      // The call to `exactInputSingle` executes the swap.
      amountOut = swapRouter.exactInputSingle(params);
  }




      // for sushiswap
  
	

    function sushiDAIWETHswapToken(address _tokenIn, address _tokenOut) public  {
      uint _amountIn = IERC20Minimal(_tokenIn).balanceOf(address(this));
          IERC20Minimal(_tokenIn).approve(Router2, _amountIn);
          
          address[] memory path;
          path = new address[](2);
          path[0] = _tokenIn;
          path[1] = _tokenOut;
        
          IUniswapV2Router02(Router2).swapExactTokensForTokens(_amountIn, getAmountOutMin(Router2,_tokenIn,_tokenOut,_amountIn), path, address(this), block.timestamp + deadline);
        }

    function sushiWETHDAIswapToken(address _tokenIn, address _tokenOut) public  {
      uint _amountIn = IERC20Minimal(_tokenIn).balanceOf(address(this));
          IERC20Minimal(_tokenIn).approve(Router2, _amountIn);
          
          address[] memory path;
          path = new address[](2);
          path[0] = _tokenIn;
          path[1] = _tokenOut;
        
          IUniswapV2Router02(Router2).swapExactTokensForTokens(_amountIn, getAmountOutMin(Router2,_tokenIn,_tokenOut,_amountIn), path, address(this), block.timestamp + deadline);
        }

   function UniswapToSushiwapTrade(address _token1, address _token2) external onlyOwner {
        uniDAIWETHswapExactInputSingle( _token1,_token2);
        sushiWETHDAIswapToken(_token2,_token1);
      //   uint endBalance = IERC20Minimal(_token1).balanceOf(address(this));
      // // require(endBalance > startBalance, "Trade Reverted, No Profit Made");
      //  profit= endBalance -startBalance;
      //  emit TradeSucces(assest,base,profit,true);
   }
    function SushiwapToUniswapTrade(address _token1, address _token2) external onlyOwner {
       sushiDAIWETHswapToken(_token1,_token2);
        uniWETHDAIswapExactInputSingle(_token2,_token1);
      // // require(endBalance > startBalance, "Trade Reverted, No Profit Made");
      //  profit= endBalance -startBalance;
      //  emit TradeSucces(assest,base,profit,true);
   }

     function getBalance (address _tokenContractAddress) external view  returns (uint256) {
		uint balance = IERC20Minimal(_tokenContractAddress).balanceOf(address(this));
		return balance;
	}
		function recoverEth() external onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}
    
    
	function recoverTokens(address tokenAddress) external onlyOwner {
	     IERC20Minimal token = IERC20Minimal(tokenAddress);
		token.transfer(msg.sender, token.balanceOf(address(this)));
     	}
   
     receive ()  payable external{
      _balance[msg.sender] += msg.value;

    }



}
