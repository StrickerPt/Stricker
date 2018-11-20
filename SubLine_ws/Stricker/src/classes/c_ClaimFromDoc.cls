public class c_ClaimFromDoc {

    public Account acc {get;set;}
    public Documentos_financeiros__c doc {get;set;}
    public List<UtilClaims.LinhasDoc> linhas {get;set;}
    public String claimDoc {get;set;}
    
    public c_ClaimFromDoc(ApexPages.StandardController std){
        doc = [Select Id, Conta__c, Name, Ftstamp__c, Valor_credito_emitido_moeda__c, Valor_credito_emitido_euros_regularizado__c, Valor_credito_emitido_euros__c, Valor_credito_emitido_moeda_regularizado__c, Data_de_pagamento__c,
               Valor_debito_emitido_moeda_regularizado__c, Valor_debito_emitido_euros_regularizado__c, Valor_debito_emitido_euros__c, Valor_debito_emitido_moeda__c, CurrencyIsoCode, Tipo_de_documento__c, Data__c,
               Data_de_validade__c, Valor_debito__c From  Documentos_financeiros__c where Id = :std.getId()];
        acc = [Select Id,Name, Numero_de_cliente__c From Account Where Id = :doc.Conta__c];
        linhas = IntegratorClaims.getLines(doc.Ftstamp__c, '');
        claimDoc = Json.serialize(new UtilClaims.NewClaimLine(doc));
    }
}