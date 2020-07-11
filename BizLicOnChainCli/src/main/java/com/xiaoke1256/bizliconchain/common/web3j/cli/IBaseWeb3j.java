package com.xiaoke1256.bizliconchain.common.web3j.cli;

import org.web3j.abi.datatypes.Type;

import java.math.BigInteger;
import java.util.List;

/**
 * @Datetime: 2020/6/23   10:35
 * @Author: Xia rong tao
 * @title
 */

public interface IBaseWeb3j {

    /**
     * ִ�к�Լ���
     *
     * @param fromAddr        ֧����ַ
     * @param fromPrivateKey  ֧����ַ˽Կ
     * @param hashVal         ��Լ��ַ
     * @param month           ��Լ����
     * @param gasPrice        ��������
     * @param inputParameters ��������
     * @return hash
     */
    String transact(String fromAddr, String fromPrivateKey, String hashVal, String month, BigInteger gasPrice, BigInteger gasLimit, List<Type> inputParameters);

}

