public class b_DeleteProds implements Database.Batchable<sObject>{
    public Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([Select id From Product2 Where RecordType.Name != 'Taxa' And ProductCode != 'NSGEN']);
    }
    
    public void execute(Database.BatchableContext BC, List<Product2> scope){
        delete scope;
    }
    
    public void finish(Database.BatchableContext BC){}
}