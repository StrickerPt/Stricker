public with sharing class c_ClaimsHomePage{
    public List<Case> casos {get;set;}
    public c_ClaimsHomePage(){
        casos = [Select id, Account.Name, CaseNumber, Status, Sub_Estado__c, CreatedDate from Case];
        
    }
}