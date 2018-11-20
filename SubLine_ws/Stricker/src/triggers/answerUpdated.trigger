trigger answerUpdated on Resposta__c (before update) {
    for(Resposta__c a : Trigger.new){
        if((Trigger.oldMap.get(a.Id).Resposta_em_texto__c != a.Resposta_em_texto__c && a.Resposta_em_texto__c != null)||
           (Trigger.oldMap.get(a.Id).Resposta_em_numero__c != a.Resposta_em_numero__c && a.Resposta_em_numero__c != null)||
           (Trigger.oldMap.get(a.Id).Resposta_em_moeda__c != a.Resposta_em_moeda__c && a.Resposta_em_moeda__c != null) ||
           (Trigger.oldMap.get(a.Id).Resposta_em_multipicklist__c != a.Resposta_em_multipicklist__c && a.Resposta_em_multipicklist__c != null)||
           (Trigger.oldMap.get(a.Id).Resposta_em_picklist__c != a.Resposta_em_picklist__c && a.Resposta_em_picklist__c != null)){
               a.Resposta_preenchida__c	 = true;
           }else if(a.Resposta_em_texto__c == null &&
                    a.Resposta_em_numero__c == null && 
                    a.Resposta_em_moeda__c == null &&
                    a.Resposta_em_multipicklist__c == null &&
                    a.Resposta_em_picklist__c == null){
               a.Resposta_preenchida__c	 = false;
           }
    }
}