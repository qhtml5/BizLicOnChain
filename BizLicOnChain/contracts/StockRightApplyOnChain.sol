pragma solidity ^0.6.0;

import { AicOrgansHolderProxy } from "./AicOrgansHolderProxy.sol";
import { BaseStockRightApplyOnChain } from "./BaseStockRightApplyOnChain.sol";
import { ArrayUtils } from "./ArrayUtils.sol";
import { StringUtils } from "./StringUtils.sol";

contract StockRightApplyOnChain is BaseStockRightApplyOnChain {
    constructor() public{
        creator = msg.sender;
    }
    
    /**
     * 仅（市监局）管理员才可以执行
     */
    modifier onlyAdmin() {
        //tx.origin 是合约的发起方，而msg.sender是上一级调用者的地址
		require(AicOrgansHolderProxy(aicOrganHolder).isAdmin(tx.origin),"Unauthorized operation!");
		_;
    }

    /**
	 *发起股权转让
	 * uniScId 统一社会信用码
	 * transferorCetfHash 出让方股东身份证件信息
	 * investorName 受让方股东姓名
	 * investorCetfHash 受让方股东身份证件信息
	 * merkel 默克尔值
	 * cptAmt 转让份额（元）
	 * price 转让价格（以太币，wei）
	 * 返回是否成功
	 */
	function startStockTransfer(string memory uniScId,string memory transferorCetfHash,string memory investorName,
			string memory investorCetfHash,bytes32 merkel,uint cptAmt,uint price)public returns (bool){
		require(bytes(uniScId).length>0);
		require(bytes(investorCetfHash).length>0);
        require(bytes(transferorCetfHash).length>0);
		//出在让方存这个股东，且账号就是操作人。
		bool sucess;
        bytes memory result;
		(sucess,result)= stockHolderContract.call(abi.encodeWithSignature("checkStockHoldersAccount(string,string,address)",uniScId,transferorCetfHash,tx.origin));
		require(sucess,'Remote invork fail!');
		require(abi.decode(result,(bool)),'You are not the stock Holder!');
		//把所有的申请案号拿出来取其最大者。
		require(!ArrayUtils.contains(stockRightApplyKeys[uniScId],investorCetfHash),'This investor are in apply flow,please finish the flow then start this flow.');
		stockRightApplys[uniScId][investorCetfHash].uniScId=uniScId;
		stockRightApplys[uniScId][investorCetfHash].investorName=investorName;
		stockRightApplys[uniScId][investorCetfHash].investorCetfHash=investorCetfHash;
		stockRightApplys[uniScId][investorCetfHash].merkel=merkel;
		stockRightApplys[uniScId][investorCetfHash].cptAmt=cptAmt;
		stockRightApplys[uniScId][investorCetfHash].price=price;
		stockRightApplys[uniScId][investorCetfHash].status='待董事会确认';
		stockRightApplyKeys[uniScId].push(investorCetfHash);
		return true;
	}

	/**
      设置新股东账号
	  uniScId 统一社会信用码
      investorCetfHash 新股东身份证件信息
      investorAccount 新股东账号
    */
	function setNewStockHolderAccount(string memory uniScId,string memory investorCetfHash,address payable investorAccount) public returns (bool){
        require(bytes(uniScId).length>0);
        require(bytes(investorCetfHash).length>0);
		//出在让方存这个股东，且账号就是操作人。
		string memory transferorCetfHash = stockRightApplys[uniScId][investorCetfHash].transferorCetfHash;
		//require(stockHolders[uniScId][transferorCetfHash].investorAccount==tx.origin);
		//状态是否正确
        require(StringUtils.equals(stockRightApplys[uniScId][investorCetfHash].status,'待董事会确认'),'This apply at the wrong state.');
		stockRightApplys[uniScId][investorCetfHash].investorAccount=investorAccount;
		return true;
	}
    
    //出让方公司的董事会确认转让（TODO 董事会可以驳回）
	function comfirmByDirectors(string memory uniScId,string memory investorCetfHash) public returns (bool){
		require(bytes(uniScId).length>0);
        require(bytes(investorCetfHash).length>0);
        require(stockRightApplys[uniScId][investorCetfHash].investorAccount==address(0),'必须设置新股东账号。');
		//TODO 检查当前账号就是公司的董事会账号
		//状态是否正确
		require(StringUtils.equals(stockRightApplys[uniScId][investorCetfHash].status,'待董事会确认'),'This apply at the wrong state.');
		stockRightApplys[uniScId][investorCetfHash].status='待付款';
		return true;
	}
    
    //受让方出资
	function payForStock(string memory uniScId,string memory investorCetfHash)public payable returns (bool){
		require(bytes(uniScId).length>0);
        require(bytes(investorCetfHash).length>0);
        //TODO 检查合约状态
		require(msg.value>0);
		//检查出资额
		require(msg.value>=stockRightApplys[uniScId][investorCetfHash].price);
		stockRightApplys[uniScId][investorCetfHash].price=msg.value;//把实际支付金额放到price中
		stockRightApplys[uniScId][investorCetfHash].status='待发证机关备案';
		return true;
	}
	
    
    /**
     * 工商局备案(市监局操作)
     * uniScId 统一社会信用码
     * investorCetfHash 受让方股东身份证件信息
     * isPass 是否审核通过
     * reason 审核不通过原因
     */
    function backUp(string memory uniScId,string memory investorCetfHash,bool isPass,string memory reason)public onlyAdmin returns (bool){
    	require(bytes(uniScId).length>0);
        require(bytes(investorCetfHash).length>0);
        require(StringUtils.equals(stockRightApplys[uniScId][investorCetfHash].status,'待发证机关备案'));
        if(isPass){
        	//调用stockHolderContract创建新的股权人
        	//先检查新股东是否已存在。
        	bool sucess;
        	bytes memory result;
        	(sucess,result) = stockHolderContract.call(abi.encodeWithSignature("getStockHolderCptAmt(string,string)",uniScId,investorCetfHash));
        	require(sucess,'Remote invork fail!');
			uint newCptAmt = abi.decode(result,(uint));
			if(newCptAmt>0){//大于0表示新股东已存在
				//调用增资函数
				(sucess,result) = stockHolderContract.call(abi.encodeWithSignature("increCpt(string,string,string,uint256)",uniScId,investorCetfHash,'',stockRightApplys[uniScId][investorCetfHash].cptAmt));
				require(sucess,'Remote invork fail!');
				require(abi.decode(result,(bool)),'something wrong when invork the  increCpt.');
			}else{
				//调用创建新股东。
				(sucess,result) = stockHolderContract.call(abi.encodeWithSignature("putStockHolder(string,string,string,address,string,uint256)"
					,uniScId,investorCetfHash
					,stockRightApplys[uniScId][investorCetfHash].investorName
					,stockRightApplys[uniScId][investorCetfHash].investorAccount
					,''
					,stockRightApplys[uniScId][investorCetfHash].cptAmt));
				require(sucess,'Remote invork fail!');
				require(abi.decode(result,(bool)),'something wrong when invork the  increCpt.');					
			}
        	//旧的股权人扣除一定的股权。
        	//如果扣完则删除旧的股权人。
        	//申请案设置成完成。
        	stockRightApplys[uniScId][investorCetfHash].isSuccess='1';
        	stockRightApplys[uniScId][investorCetfHash].status='结束';
        	//把以太币支付给股权出让方
        }else{
        	//检查一下以太币够不够
        	require(address(this).balance>=stockRightApplys[uniScId][investorCetfHash].price,'The balace of the contract is not enough.');
        	//申请案设置成完成（失败）
        	stockRightApplys[uniScId][investorCetfHash].isSuccess='0';
        	stockRightApplys[uniScId][investorCetfHash].status='结束';
        	stockRightApplys[uniScId][investorCetfHash].failReason=reason;
        	//把以太币支退给股权受让方
        	stockRightApplys[uniScId][investorCetfHash].investorAccount.transfer(stockRightApplys[uniScId][investorCetfHash].price);
        }
    	return true;
    }


}
