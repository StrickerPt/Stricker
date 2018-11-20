trigger t_insertStandardPB on Product2 (after insert) {
    String standardPBId;
    if(!Test.isRunningTest()){
        standardPBId = [Select id From Pricebook2 Where isStandard = true].id;
    }else{
        standardPBId = Test.getStandardPricebookId();
    }
    List<PricebookEntry> pbToUpsert = new List<PricebookEntry>();
    for (Product2 product : Trigger.new) {
        PricebookEntry pbeStandard = new PricebookEntry();
        pbeStandard.Pricebook2Id = standardPBId;
        pbeStandard.Product2Id = product.id;
        pbeStandard.ChaveExterna__c = product.id +''+ standardPBId+'EUR';
        pbeStandard.UseStandardPrice=FALSE;
        pbeStandard.IsActive = true;
        pbeStandard.CurrencyIsoCode = 'EUR';
        pbeStandard.UnitPrice = 0;
        pbToUpsert.add(pbeStandard);
        
        PricebookEntry pbeStandard2 = new PricebookEntry();
        pbeStandard2.Pricebook2Id = standardPBId;
        pbeStandard2.Product2Id = product.id;
        pbeStandard2.ChaveExterna__c = product.id +''+ standardPBId+'USD';
        pbeStandard2.UseStandardPrice=FALSE;
        pbeStandard2.IsActive = true;
        pbeStandard2.CurrencyIsoCode = 'USD';
        pbeStandard2.UnitPrice = 0;
        pbToUpsert.add(pbeStandard2);
        
        PricebookEntry pbeStandard3 = new PricebookEntry();
        pbeStandard3.Pricebook2Id = standardPBId;
        pbeStandard3.Product2Id = product.id;
        pbeStandard3.ChaveExterna__c = product.id +''+ standardPBId+'GBP';
        pbeStandard3.UseStandardPrice=FALSE;
        pbeStandard3.IsActive = true;
        pbeStandard3.CurrencyIsoCode = 'GBP';
        pbeStandard3.UnitPrice = 0;
        pbToUpsert.add(pbeStandard3);
        
        PricebookEntry pbeStandard4 = new PricebookEntry();
        pbeStandard4.Pricebook2Id = standardPBId;
        pbeStandard4.Product2Id = product.id;
        pbeStandard4.ChaveExterna__c = product.id+''+ standardPBId+'PLN';
        pbeStandard4.UseStandardPrice=FALSE;
        pbeStandard4.IsActive = true;
        pbeStandard4.CurrencyIsoCode = 'PLN';
        pbeStandard4.UnitPrice = 0;
        pbToUpsert.add(pbeStandard4);
    }
    
    Database.UpsertResult[] srPbe = DataBase.Upsert(pbToUpsert,PricebookEntry.ChaveExterna__c);
}