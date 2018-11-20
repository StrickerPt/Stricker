/*
***********************************************************************
Created By    :- Marco Galvão
Created Date  :- 14 DEC 2016
Desc          :- Checks if main contact already exists
***********************************************************************
*/
trigger ValidaTemplate on Template_de_relatorio__c (before insert, before update) {
    Set<string> templateLingua  = new Set<string>();
    for(Template_de_relatorio__c con : Trigger.New){
        templateLingua.add(con.Lingua_do_Template__c);
    }
    Map<Id, Template_de_relatorio__c> Templates = new Map<Id, Template_de_relatorio__c> ([Select Id, Ativo__c, Lingua_do_Template__c From Template_de_relatorio__c Where Ativo__c = True]);
    
    for(Template_de_relatorio__c c: Trigger.New){
    for(Template_de_relatorio__c s: Templates.values()){
            if(s.Lingua_do_Template__c == c.Lingua_do_Template__c){
                if(c.Ativo__c == true){
                    c.Ativo__c.addError('Já existe Template para este idioma.');
                }
            }
        }
    }
}