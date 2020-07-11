package com.xiaoke1256.bizliconchain.common.web3j.cli;

import com.alibaba.fastjson.JSONObject;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
//import org.springframework.beans.factory.annotation.Value;
//import org.springframework.stereotype.Component;


import org.web3j.abi.FunctionEncoder;
import org.web3j.abi.TypeReference;
import org.web3j.abi.datatypes.Bool;
import org.web3j.abi.datatypes.Function;
import org.web3j.abi.datatypes.Type;
import org.web3j.crypto.Credentials;
import org.web3j.crypto.RawTransaction;
import org.web3j.crypto.TransactionEncoder;
import org.web3j.protocol.Web3j;
import org.web3j.protocol.core.DefaultBlockParameterName;
import org.web3j.protocol.core.methods.response.*;

import org.web3j.protocol.http.HttpService;
import org.web3j.utils.Numeric;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.List;

/**
 * @Datetime: 2020/6/23   10:36
 * @Author: Xia rong tao
 * @title
 */

//@Component
public class BaseWeb3jImpl implements IBaseWeb3j {

    private static final Logger LOG = LoggerFactory.getLogger(BaseWeb3jImpl.class);


    static Web3j web3j;

//    @Value("${contract.url}")
    private   String URL;


//    @Value("${contract.addGas}")
    private BigInteger addGas;



//    @Value("${contract.isAddGas}")
    private boolean isAddGas;




    public String transact(String fromAddr, String fromPrivateKey, String hashVal, String month, BigInteger gasPrice, BigInteger gasLimit, List<Type> inputParameters) {
        EthSendTransaction ethSendTransaction = null;
        BigInteger nonce = BigInteger.ZERO;
        String hash = null;
        try {
            if(web3j == null){
                web3j = Web3j.build(new HttpService(URL));
            }
            EthGetTransactionCount ethGetTransactionCount = web3j.ethGetTransactionCount(
                    fromAddr,
                    DefaultBlockParameterName.PENDING
            ).send();
            //���������Ƿ�������ʵʱ�г�gas���ã�����ָ��gas���ã��ӿ�������
            if(isAddGas){
                 BigInteger gas  = web3j.ethGasPrice().send().getGasPrice();
                 LOG.info("��ȡ����gasPrice{}",gas);
                 gasPrice = addGas.add(gas);
            }
            //����ָ����ַ�����Ľ���������
            nonce =  ethGetTransactionCount.getTransactionCount();
            List outputParameters = new ArrayList();
            TypeReference<Bool> typeReference = new TypeReference<Bool>() {
            };
            outputParameters.add(typeReference);
            LOG.info("�����󹤵�gasPriceΪ��{}",gasPrice);
            Function function = new Function(
                    month,
                    inputParameters,
                    outputParameters);
            String encodedFunction = FunctionEncoder.encode(function);
            Credentials credentials = Credentials.create(fromPrivateKey);
            RawTransaction rawTransaction = RawTransaction.createTransaction(nonce, gasPrice, gasLimit, hashVal,
                    encodedFunction);
            byte[] signedMessage = TransactionEncoder.signMessage(rawTransaction, credentials);
            String hexValue = Numeric.toHexString(signedMessage);
            ethSendTransaction = web3j.ethSendRawTransaction(hexValue).sendAsync().get();
            hash = ethSendTransaction.getTransactionHash();
            LOG.info(JSONObject.toJSONString(ethSendTransaction));
        } catch (Exception e) {
            if (null != ethSendTransaction) {
                LOG.info("ʧ�ܵ�ԭ��" + ethSendTransaction.getError().getMessage());
                LOG.info("������fromAddr = " + fromAddr);
                LOG.info("������month = " + month);
                LOG.info("������gasPrice = " + gasPrice);
                LOG.info("������gasLimit = " + gasLimit);
                LOG.info("������inputParameters = " + JSONObject.toJSONString(inputParameters));
            }
            throw new RuntimeException(e);
        }

        return hash;
    }
}