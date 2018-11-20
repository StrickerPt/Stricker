public class c_DesignerViewerProdutos {
    public Map<String, Product> prods {get;set;}
    public Opportunity opp {get;set;}
    public Map<String, Integer> totalProdsCor {get;set;}

    public c_DesignerViewerProdutos(ApexPages.StandardController stdCtrl){
        prods = new Map<String, Product>();
        totalProdsCor = new Map<String, Integer>();

        opp = [Select id, Alerta_Mudanca_de_Cor__c,
               (Select Id,Product2.RecordType.DeveloperName, Referencia_Sku__c,Referencia_relacionada__c,Componente_da_impressao__c,Product2.Url_Imagem__c,Product2.Nome_Para_User__c,Codigo_de_cor__c,Altura__c,Comprimento__c,
                Numero_de_repeticoes__c,Alinhamento__c,Pantone_Cor__c,Fonte__c,Texto_a_customizar__c,Cores_de_customizacao__c,Tecnica__c,Numero_de_impressoes__c,Opportunity.Dossier_de_repeticao__c,ProductCode,Stamp__c,
                Opportunity.Comentarios_para_maquete__c,Quantity,opportunity.Retificacoes_pedidas_pelo_comercial__c
                from OpportunityLineItems Where Product2.RecordType.DeveloperName = 'Produto')
               from Opportunity Where Id = :stdCtrl.getRecord().Id
              order by CreatedDate ASC];
        
        Map<String, String> mapRefRels = new Map<String, String>();//stamp linha original, Id sf
        for(OpportunityLineItem oli : opp.OpportunityLineItems){
            Product prod = new Product();
            prod.oli = oli;
            prod.customs = prods.containsKey(oli.Id) ? prods.get(oli.Id).customs : new List<OpportunityLineItem>();
            prods.put(oli.Id, prod);
            
            mapRefRels.put(oli.Stamp__c, oli.Id);
            
            //totalizador de quantitade de referencia
            if(!totalProdsCor.containsKey(oli.ProductCode)){
                totalProdsCor.put(oli.ProductCode, 0);
            }
            totalProdsCor.put(oli.ProductCode, totalProdsCor.get(oli.ProductCode) + (Integer) oli.Quantity);
            
            //totalizador de quantidade de referencia e cor
            String keyCor = oli.ProductCode + oli.Codigo_de_cor__c;
            if(!totalProdsCor.containsKey(keyCor)){
                totalProdsCor.put(keyCor, 0);
            }
            totalProdsCor.put(keyCor, totalProdsCor.get(keyCor) + (Integer) oli.Quantity);
        }
        for(OpportunityLineItem cust : [Select Id,Product2.RecordType.DeveloperName, Referencia_Sku__c,Referencia_relacionada__c,Componente_da_impressao__c,Product2.Url_Imagem__c,Product2.Nome_Para_User__c,Codigo_de_cor__c,Altura__c,Comprimento__c,
                Numero_de_repeticoes__c,Alinhamento__c,Pantone_Cor__c,Fonte__c,Texto_a_customizar__c,Cores_de_customizacao__c,Tecnica__c,Numero_de_impressoes__c,Opportunity.Dossier_de_repeticao__c,ProductCode,
                Opportunity.Comentarios_para_maquete__c,Quantity,opportunity.Retificacoes_pedidas_pelo_comercial__c, Product2.Tecnica__c
                from OpportunityLineItem Where Product2.RecordType.DeveloperName = 'Customizacao' and OpportunityId = :opp.Id]){
                    if(prods.containsKey(cust.Referencia_relacionada__c)) {
                        prods.get(cust.Referencia_relacionada__c).customs.add(cust);
                    }else if(mapRefRels.containsKey(cust.Referencia_relacionada__c)){
                        prods.get(mapRefRels.get(cust.Referencia_relacionada__c)).customs.add(cust);
                    }
        }
    }
    
    public class Product{
        public OpportunityLineItem oli {get;set;}
        public List<OpportunityLineItem> customs {get;set;}
    }
}