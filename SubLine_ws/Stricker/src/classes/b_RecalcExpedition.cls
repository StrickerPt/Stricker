global class b_RecalcExpedition implements Database.batchable<sObject>,Database.AllowsCallouts, Schedulable{
    Set<Id> expeditionsIds = new Set<Id>();
    
    public b_RecalcExpedition(Set<Id> expeditionsIds){
        this.expeditionsIds = expeditionsIds;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([Select Id,Morada_de_entrega__r.Pais__c,Morada_de_entrega__r.Codigo_postal__c,Morada_de_entrega__r.Localidade__c,
                                         Dossier__r.Amount,Dossier__r.CurrencyIsoCode,Dossier__r.Account.BillingCountryCode,Dossier__r.Account.BillingPostalCode,
                                         Transportadora__c,Linha_de_transporte__c,Linha_de_despacho__c,
                                         (select id,Volume__c,Peso__c from Linhas_da_expedicao__r)
                                         from Expedicao__c Where Id in:expeditionsIds]);
    }
    
    global void execute(Database.BatchableContext info, List<Expedicao__c> scope){
        List<OpportunityLineItem> olis = new List<OpportunityLineItem>();
        
        String token = w_StrickerService.auth();
        for(Expedicao__c exp : scope){
            //calcula peso/volume para recalculo do valor da expedicao
            Decimal volume = 0;
            Decimal peso = 0;
            for(OpportunityLineItem oli : exp.Linhas_da_expedicao__r){
                volume += oli.Volume__c != null ? oli.Volume__c : 0;
                peso += oli.Peso__c != null ? oli.Peso__c : 0;
            }
            WrapperCalculoTransportadora result = 
                w_StrickerService.calculaTransporte(
                    token,//token
                    exp.Morada_de_entrega__r.Pais__c,//paisCliente 
                    exp.Morada_de_entrega__r.Codigo_postal__c,//codPostalCliente 
                    exp.Morada_de_entrega__r.Localidade__c,//localidade 
                    String.valueOf(exp.Dossier__r.Amount),//total_encomenda 
                    String.valueOf(peso),//peso 
                    String.valueOf(volume),//volume 
                    exp.Dossier__r.CurrencyIsoCode,//moeda 
                    exp.Dossier__r.Account.BillingCountryCode,//country_iso 
                    exp.Dossier__r.Account.BillingPostalCode);//codpostal 
            
            String field = exp.Transportadora__c.replace(' ', '_');
            if(result != null && result.get(field) != null){
                if(exp.Linha_de_transporte__c != null){
                    OpportunityLineItem oliT = new OpportunityLineItem();
                    oliT.Id = exp.Linha_de_transporte__c;
                    oliT.UnitPrice = (result.get(field).valor_transporte != null ? result.get(field).valor_transporte : 0);
                    oliT.Preco_unitario__c = oliT.UnitPrice;
                    olis.add(oliT);
                }
                if(exp.Linha_de_despacho__c != null){
                    OpportunityLineItem oliD = new OpportunityLineItem();
                    oliD.Id = exp.Linha_de_despacho__c;
                    oliD.UnitPrice = (result.get(field).valor_despacho != null ? result.get(field).valor_despacho : 0);
                    oliD.Preco_unitario__c = oliD.UnitPrice;
                    olis.add(oliD);
                }
            }
        }
        w_StrickerService.clearSessions(token);
        if(!olis.isEmpty()){
            Database.update(olis, false);
            DateTime now  = DateTime.now();
            String nowToString = String.ValueOf(now);
            DateTime nextRunTime = now.addSeconds(30);
            String cronString = '' + nextRunTime.second() + ' ' + nextRunTime.minute() + ' ' + nextRunTime.hour() + ' ' + nextRunTime.day() + ' ' + nextRunTime.month() + ' ? ' + nextRunTime.year(); 
            
            Map<Id, opportunity> auxMap = new Map<Id, opportunity>([Select id from Opportunity Where Id In (Select Dossier__c From Expedicao__c Where Id In:expeditionsIds)]);
            if(!auxMap.isEmpty()){
                s_ScheduleUpdateDossier sc = new s_ScheduleUpdateDossier(auxMap.keySet());
                System.schedule('Actualiza Dossier após recalculo dos portes: '+system.now().getTime()+ ' ' + auxMap.get(auxMap.values().get(0).Id), cronString, sc);
            }
        }
    }     
    global void finish(Database.BatchableContext info){}
    
    
    public void execute(SchedulableContext SC) {
        Database.executeBatch(this, 50);
    }
    
}