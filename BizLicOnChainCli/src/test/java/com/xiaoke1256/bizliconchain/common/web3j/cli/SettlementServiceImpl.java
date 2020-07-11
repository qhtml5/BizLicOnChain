package com.xiaoke1256.bizliconchain.common.web3j.cli;

//import com.blockchain.server.contractGzhz.service.SettlementService;
//import com.blockchain.server.contractGzhz.web3j.IBaseWeb3j;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
//import org.springframework.beans.factory.annotation.Autowired;
//import org.springframework.beans.factory.annotation.Value;
//import org.springframework.stereotype.Component;
import org.web3j.abi.datatypes.Type;

import java.math.BigInteger;
import java.util.Arrays;
import java.util.Date;
import java.util.List;

/**
 * @Datetime: 2020/6/23   11:47
 * @Author: Xia rong tao
 * @title
 */
//@Component
public class SettlementServiceImpl  {

    private static final Logger LOG = LoggerFactory.getLogger(SettlementServiceImpl.class);


    /*��Լ��ַ*/
    //@Value("${contract.ctAddr}")
    private String ctAddr;
    /*��ʼ��ַ*/
    //@Value("${contract.startAddr}")
    private String startAddr;
    /*���ҵ�ַ*/
    //@Value("${contract.sendAddr}")
    private String sendAddr;
    /*���ҵ�ַ˽Կ*/
    //@Value("${contract.sendAddrPk}")
    private String sendAddrPk;

    //@Value("${contract.gasLimit}")
    private BigInteger CT_GAS_LIMIT;

    //@Value("${contract.gasPrice}")
    private BigInteger CT_GAS_PRICE;

    //@Autowired
    IBaseWeb3j iBaseWeb3j;

    /**
     ���÷���
    **/
    public void test() {

        try {
             
            List<Type> inputParameters = Arrays.asList( );
            iBaseWeb3j.transact(sendAddr,sendAddrPk,ctAddr,"month_name", CT_GAS_PRICE, CT_GAS_LIMIT,inputParameters);
        }catch (Exception ex){

            LOG.error("�����쳣",ex);
        }

    }
}