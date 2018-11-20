/* Batch class to update force one update on all of the opportunities which at least one of their expeditions' address updated.
 * Used in: t_Morada;
 * */
public class b_UpdateLinesAddress implements Database.Batchable<sObject>, Database.AllowsCallouts{
    public Map<Id, Morada_de_entrega__c> addresses;
    public b_UpdateLinesAddress(Set<Id> adds){
        addresses = new Map<Id, Morada_de_entrega__c>([Select Id From Morada_de_entrega__c Where Id In :adds]);
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        String lista = '(';
        boolean isFirst = true;
        for(Id var : addresses.keySet()){
            if(isFirst){
                isFirst = false;	
            }else{
                lista += ',';
            }
            lista += '\'' + var + '\'';
        }
        lista += ')';
        return Database.getQueryLocator('Select Id From Opportunity Where Id In (Select OpportunityId From OpportunityLineItem Where Expedicao__r.Morada_de_entrega__c In ' + lista + ')' );
    }
    
    public void execute(Database.BatchableContext BC, List<Opportunity> scope){
        for(Opportunity opp : scope){
            //Keidy - Alteração do metodo para receber o mexeLinhas como parametro
            Integrator.actDossierDoWork(Integrator.getOpp(opp.Id), true);
        }
    }
    
    public void finish(Database.BatchableContext BC){}
}