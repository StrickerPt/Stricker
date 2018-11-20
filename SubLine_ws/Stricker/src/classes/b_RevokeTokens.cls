public class b_RevokeTokens implements Schedulable, Database.Batchable<sObject>{
    
    public void execute(System.SchedulableContext SC){
        Database.executeBatch(this);
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([Select id From Token_Site__c Where CreatedDate < :System.now().addHours(-4)]);
    }
    
    public void execute(Database.BatchableContext BC, List<Token_Site__c> scope){
        delete scope;
    }
    
    public void finish(Database.BatchableContext BC){}
}