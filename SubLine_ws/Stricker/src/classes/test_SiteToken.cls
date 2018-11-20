@isTest
public class test_SiteToken {
    static testmethod void testSiteToken(){
        test.startTest();
        
        rest_SiteToken.doPost('wfhfw3fjf', '123456789', '125.258.25', 30, 'http://istoeumteste');
         
        test.stopTest();  
    }
}