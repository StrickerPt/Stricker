public class b_UpdatePrecosTransp implements Database.Batchable<sObject>,Database.AllowsCallouts{
    public Set<Id> ids;
    public b_UpdatePrecosTransp(Set<Id> ids){
        this.ids = ids;
    }
    public Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([Select id, Pais__c, Codigo_postal_original__c, Localidade_original__c, Quantidade_original__c, Peso__c, Volume__c, CurrencyIsoCode,
                                         Portes_para_recolha_devolucao__c From OrderItem Where Id in :ids]);
    }
    
    public void execute(Database.BatchableContext BC, List<OrderItem> scope){
        String token = w_StrickerService.auth();
        for(OrderItem item: scope){
            
            WrapperCalculoTransportadora result = 
                w_StrickerService.calculaTransporte(
                    token,//token
                    item.Pais__c,//paisCliente 
                    item.Codigo_postal_original__c,//codPostalCliente 
                    item.Localidade_original__c,//localidade 
                    String.valueOf(item.Quantidade_original__c),//total_encomenda VALOR*****
                    String.valueOf(item.Peso__c),//peso 
                    String.valueOf(item.Volume__c),//volume 
                    item.CurrencyIsoCode,//moeda 
                    'PT',//country_iso 
                    '3060-372');//codpostal 
            system.debug(result);
            for(String field : WrapperCalculoTransportadora.fields){
                if(result.get(field) != null){
                    if(item.Pais__c == 'PT' || item.Pais__c == 'ES'){
                        if(field == 'CTT'){
                            item.Portes_para_recolha_devolucao__c = (result.get(field).valor_transporte != null ? result.get(field).valor_transporte : 0);
                            break;
                        }
                    }else{
                        if(field == 'TNT_Economy'){
                            item.Portes_para_recolha_devolucao__c = (result.get(field).valor_transporte != null ? result.get(field).valor_transporte : 0);
                            break;
                        }
                    }
                }
            }
        }
        w_StrickerService.clearSessions(token);
        update scope;
    }
    
    public void finish(Database.BatchableContext BC){}
}