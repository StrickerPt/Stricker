public class sh_DeletePrecoPorCliente implements Schedulable, Database.Batchable<sObject>,Database.AllowsCallouts{
public void execute(SchedulableContext sc) {
        system.debug('Corri');
        
        Database.executeBatch(this, 1);
    }
    
    public List<AggregateResult> start(Database.BatchableContext BC){
        return [Select Cliente__c, Count(Id) total From Preco_por_cliente__c Where LastModifiedDate >= :System.now().addHours(-2) And isDeleted = true group by Cliente__c ALL ROWS];
    }
    
    public void execute(Database.BatchableContext BC, List<AggregateResult> scope){
        for(AggregateResult result : scope){
            system.debug(result.get('Cliente__c') + ' : ' + ((Decimal) result.get('total')));
            String accId = (String) result.get('Cliente__c');
            Account acc = [Select Id,OwnerId,Numero_de_cliente__c,
                           (Select Id, Produto__r.ProductCode,Produto__r.Tamanho__c,Valor__c,Data_de_inicio__c,Data_de_fim__c From Precos_por_cliente__r)
                           From Account Where Id = :accId];
            User user = [Select Id, Codigo_de_Utilizador__c From User Where Id = :acc.OwnerId];
            
            Integrator.criaPrecosClienteWork(acc, user);
        }
    }
    
    public void finish(Database.BatchableContext BC){}
}