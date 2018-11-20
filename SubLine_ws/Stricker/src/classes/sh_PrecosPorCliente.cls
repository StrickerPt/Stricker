public class sh_PrecosPorCliente implements Schedulable, Database.Batchable<sObject>,Database.AllowsCallouts{
	public void execute(SchedulableContext sc) {
        system.debug('Corri');
        
        Database.executeBatch(this, 1);
    }
    
    public List<AggregateResult> start(Database.BatchableContext BC){
        return [Select Cliente__c, Count(Id) total From Preco_por_cliente__c Where LastModifiedDate >= :System.now().addHours(-5) group by Cliente__c];
            // Database.getQueryLocator([Select id From Account Where Id In (Select Cliente__c From Preco_por_cliente__c Where LastModifiedDate >= :System.now().addHours(-2))]);
    }
    
    public void execute(Database.BatchableContext BC, List<AggregateResult> scope){
        for(AggregateResult result : scope){
            system.debug(result.get('Cliente__c') + ' : ' + ((Decimal) result.get('total')));
            String accId = (String) result.get('Cliente__c');
            Account acc = Integrator.buildAccountPPC(accId);
            User user = Integrator.buildUserPPC(acc.OwnerId);
            
            if((Decimal) result.get('total') > 1){
                system.debug('criar');
                Integrator.criaPrecosClienteWork(acc, user);
            }else{
                system.debug('atualizar');
                Integrator.updatePrecosClienteWork(acc, user);
            }
        }
    }
    
    public void finish(Database.BatchableContext BC){}
}