trigger t_createAnswersVisitReport_INS_SAC on Relatorio__c (before insert, after insert) {
    Set<Id> ids = new Set<Id>();
    if(Trigger.isBefore){
        List<Template_de_relatorio__c> templateList = [Select Id, Ativo__c, Lingua_do_Template__c From Template_de_relatorio__c];
        
        //Vai buscar os ids das contas dos relatorios que estao a ser inseridos
        Set<Id> accIds = new Set<Id>();
        for(Relatorio__c r : Trigger.new){
            accIds.add(r.Conta__c);
        }
        Map<Id, Account> accMap = new Map<Id, Account>([Select id, CurrencyIsoCode from Account Where Id In :accIds]);
        for(Relatorio__c vr : trigger.new){
            for(Template_de_relatorio__c template : templateList ){
                if(template.Ativo__c == true && template.Lingua_do_Template__c == UserInfo.getLanguage()){
                    vr.Template_de_relatorio__c = template.Id;
                    break;
                }
            }
            ids.add(vr.Template_de_relatorio__c);
            vr.CurrencyIsoCode = accMap.get(vr.Conta__c).CurrencyIsoCode;
        }
    }else {
        for(Relatorio__c vr : trigger.new){
            ids.add(vr.Template_de_relatorio__c);
        }
    }
    if(Trigger.isAfter){
        List<Resposta__c> newAnswers = new List<Resposta__c>();
        for(Pergunta__c question: [Select id, Template_de_relatorio__c From Pergunta__c Where Template_de_relatorio__c in :ids]){
            for(Relatorio__c vr : trigger.new){
                if(question.Template_de_relatorio__c ==  vr.Template_de_relatorio__c){
                    Resposta__c newAnswer = new Resposta__c();
                    newAnswer.Pergunta__c = question.Id;
                    newAnswer.Relatorio__c = vr.Id;
                    newAnswers.add(newAnswer);
                }
            }
        }
        if(!newAnswers.isEmpty()){
            insert newAnswers;
        }
    }
}