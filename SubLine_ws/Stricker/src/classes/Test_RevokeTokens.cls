@isTest
public class Test_RevokeTokens {
    testmethod static void test1(){
        Token_Site__c token = new Token_Site__c();
        
        insert token;
        
        Test.setCreatedDate(token.Id, DateTime.newInstance(2012,12,12));
        
        b_RevokeTokens sched = new b_RevokeTokens();
        sched.execute(null);
    }
}