@isTest
private class Test_CheckVat {
    
    static testmethod void checkVat() {
        Test.startTest();
        checkVat.checkVatPort cv = new checkVat.checkVatPort();
        cv.inputHttpHeaders_x = new Map<String,String>();
        cv.outputHttpHeaders_x = new Map<String,String>();
        cv.clientCertName_x = 'clientCertNameTest';
        cv.clientCert_x = 'clientCertTest';
        cv.clientCertPasswd_x = 'clientCertPasswd';
        cv.timeout_x = 1 * 60 * 1000;
        cv.checkVat('PT', '509300421');
        Test.stopTest();
    }
}