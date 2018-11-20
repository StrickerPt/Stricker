trigger t_Expedicao on Expedicao__c (after insert, before delete) {
    if(Trigger.isBefore){
        if(Trigger.isDelete){
            List<OpportunityLineItem> olis = new List<OpportunityLineItem>();
            Map<Id, Decimal> mapOpp = new Map<Id, Decimal>();
            List<OpportunityLineItem> transpDelete = new List<OpportunityLineItem>();
            for(OpportunityLineItem oli : [Select id, Product2.ProductCode, OpportunityId, UnitPrice From OpportunityLineItem Where Expedicao__c In :Trigger.old]){
                oli.Auxiliar_expedicao__c = 0;
                olis.add(oli);
                if(c_AddProduct.transpCodes.contains(oli.Product2.ProductCode)){
                    transpDelete.add(oli);
                }
            }
            //Reduz o custo da expedicao
            Map<Id, Opportunity> opps = new Map<Id, Opportunity>([Select Id, Custo_de_transporte_stricker__c, Autorizada__c From Opportunity Where Id In (Select Dossier__c From Expedicao__c Where Id In :Trigger.old)]);
            for(Expedicao__c exp : Trigger.old){
                if(opps.containsKey(exp.Dossier__c)){
                    if(opps.get(exp.Dossier__c).Autorizada__c == '' || opps.get(exp.Dossier__c).Autorizada__c == null){
                        if(opps.get(exp.Dossier__c).Custo_de_transporte_stricker__c == null) opps.get(exp.Dossier__c).Custo_de_transporte_stricker__c = 0;
                        
                        if(opps.get(exp.Dossier__c).Custo_de_transporte_stricker__c - (exp.Valor_custo__c != null ? exp.Valor_custo__c : 0) - (exp.Valor_transporte__c != null ? exp.Valor_transporte__c : 0) > 0){
                            opps.get(exp.Dossier__c).Custo_de_transporte_stricker__c -= (exp.Valor_custo__c != null ? exp.Valor_custo__c : 0);
                        }else{
                            opps.get(exp.Dossier__c).Custo_de_transporte_stricker__c = 0;
                        } 
                    }else{
                        exp.addError(Label.Apagar_expedicao);
                    }
                }
            }
            
            try{
                if(!opps.isEmpty()) update opps.values();
                if(!olis.isEmpty()) update olis;
                if(!transpDelete.isEmpty()) delete transpDelete;
            }catch(Exception ex){
                for(Expedicao__c exp : Trigger.old){
                    exp.addError(Label.Apagar_expedicao);
                }
            }
        }
    }else{
        if(Trigger.isInsert){
            ExpedicaoHelper.changeBox(Trigger.newMap.keySet());
        }
    }
}