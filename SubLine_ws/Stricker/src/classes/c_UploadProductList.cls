public class c_UploadProductList {
    
    public PageReference pgReturnPage;
    
    public String sId {get;set;}
    public String FileName {get;set;}
    public Opportunity opp {get;set;}
    public Blob FileContent {get;set;}
    public Map<String, PricebookEntry> auxPbe;
    public c_UploadProductList(ApexPages.StandardController standardController){
        sId = standardController.getId();
        this.opp = [select Id,Pricebook2Id,RecordType.DeveloperName from Opportunity where Id = :sId];
        String returnUrl = '/' + sID;
        auxPbe = new Map<String, PricebookEntry>();
        pgReturnPage = new PageReference(returnUrl);
        pgReturnPage.setRedirect(true);
        
        for(PricebookEntry pbe : [Select id, ProductCode, Product2.Tamanho__c, Custo_adicional__c From PricebookEntry Where Pricebook2Id = :opp.Pricebook2Id And Product2.RecordType.DeveloperName='Produto']){
            auxPbe.put(pbe.ProductCode + (pbe.Product2.Tamanho__c != null ? pbe.Product2.Tamanho__c : ''), pbe);
        }
    }
    
    public Pagereference ReadFile(){
                 
        List<OpportunityLineItem> m_OppItemList = new List<OpportunityLineItem>();
        
        try{       
            String[] m_Filelines = FileContent.toString().split('\n');
            for (Integer i = 1 ; i < m_Filelines.size() ; i++){
                String[] m_LineValues = new String[]{};
              
           		m_LineValues = m_Filelines[i].split(';');
                OpportunityLineItem m_OppItem = new OpportunityLineItem();
                if(m_LineValues.size()>0){
                    m_OppItem.OpportunityId = sId;
                    //Código produto + Tamanho se existir
                    system.debug(auxPbe);
                    m_OppItem.PricebookEntryId = auxPbe.get(m_LineValues[0].trim() + 
                                                            ((m_LineValues[1] == null || m_LineValues[1] == '') ? '' : m_LineValues[1].trim())).Id;
                    //Quantidade
                    m_OppItem.Quantity = Decimal.valueOf(m_LineValues[2].trim());
                    //Preço
                    m_OppItem.UnitPrice = Decimal.valueOf(m_LineValues[3].trim());
                    m_OppItem.Preco_Unitario__c = m_OppItem.UnitPrice;
                    m_OppItem.Valor_unitario_original__c = m_OppItem.UnitPrice;
                    m_OppItem.Total_de_customizacao__c = m_OppItem.Quantity * m_OppItem.UnitPrice;
                    //Cor
                    m_OppItem.Codigo_de_cor__c = m_LineValues[4].trim();
                }
                m_OppItemList.add(m_OppItem);
            }
            
            Database.SaveResult[] result = Database.insert(m_OppItemList, true);
            
        }catch(Exception m_Exception){
        	system.debug('Message -> Exception ' + m_Exception.getMessage() + ' ' + m_Exception.getLineNumber());
        }
        return pgReturnPage;
    }
    
    public PageReference ReadFile2Collumns(){
        List<ProdExcel> prods = new List<ProdExcel>();
        Set<String> refs = new Set<String>();
        Set<String> tamanhos = new Set<String>();
        Map<String, Decimal> quantities = new Map<String, Decimal>();
        try{       
            String[] m_Filelines = FileContent.toString().split('\n');
            for (Integer i = 1 ; i < m_Filelines.size() ; i++){
                String[] m_LineValues = m_Filelines[i].split(';');
                if(m_LineValues.size()>0){
                    String produto = m_LineValues[0];
                    String ref = produto.split('\\.')[0];
                    String cor = produto.contains('.') ? produto.split('\\.')[1].split('-')[0] : null;

                    String aux = produto.contains('.') ? produto.split('\\.')[1] : null;
                    String tamanho = aux != null && aux.contains('-') ? aux.split('-')[1] : null;
                    String quantidade = m_LineValues[1].trim();
                    ProdExcel prod = new ProdExcel(ref, cor, tamanho, Decimal.valueOf(quantidade));

                    prods.add(prod);
                    String key = prod.ref + (prod.tamanho != null ? prod.tamanho : '');
                    if(quantities.containsKey(key)){
                        quantities.put(key, quantities.get(key) + prod.quantidade);
                    }else{
                        quantities.put(key, prod.quantidade);
                    }
                    refs.add(ref);
                    tamanhos.add(tamanho);
                }
            }
            Map<String, PricebookEntry> m_pbe = new Map<String, PricebookEntry>();
            Set<Id> idProds = new Set<Id>();
            for(PricebookEntry pbe : [Select  Id,Pricebook2Id,ProductCode,Product2.ProductCode,UnitPrice,Product2Id,Product2.Cor__c,Maximo_1__c,Maximo_2__c,
                                      Maximo_3__c,Maximo_4__c,Maximo_5__c, Maximo_6__c,Maximo_7__c,Maximo_8__c,Maximo_9__c,Maximo_10__c,Minimo_1__c,Minimo_2__c,
                                      Minimo_3__c,Minimo_4__c,Minimo_5__c,Minimo_6__c,Minimo_7__c,Minimo_8__c,Minimo_9__c,Minimo_10__c,Preco_1__c,Preco_2__c,
                                      Preco_3__c,Preco_4__c,Preco_5__c,Preco_6__c,Preco_7__c,Preco_8__c,Preco_9__c,Preco_10__c,Preco_A__c,Preco_B__c,Preco_C__c,
                                      Preco_D__c,Preco_E__c,Preco_F__c,Preco_G__c,Preco_H__c,Preco_I__c,Preco_J__c,Product2.Cores_de_customizacao__c, 
                                      Product2.Name,Name, Product2.Multiplicador_Produto__c, Product2.Tamanho__c, Custo_adicional__c 
                                      From PricebookEntry 
                                      Where Pricebook2Id In (Select Pricebook2Id From Opportunity Where Id = :sId)
                                      And ProductCode In :refs
                                      And Product2.Tamanho__c In :tamanhos]){
                                          String key = pbe.ProductCode + (pbe.Product2.Tamanho__c != null ? pbe.Product2.Tamanho__c : '');
                                          m_pbe.put(key, pbe);
                                          idProds.add(pbe.Product2Id);
                                      }
            Map<Id, Preco_por_cliente__c> precosCliente = new Map<Id, Preco_por_cliente__c>();//IdProd - PC
            
            for(Preco_por_cliente__c pc : [Select Id, Produto__c, Valor__c
                                           From Preco_por_cliente__c 
                                           Where Produto__c in:idProds 
                                           And Cliente__c In (Select AccountId From Opportunity Where Id = :sId)]){
                precosCliente.put(pc.Produto__c, pc);
            }
            Account acc = [Select Id, Escalao_Hidea__c From Account Where ID In (Select AccountId From Opportunity Where Id = :sId)];
            List<OpportunityLineItem> newItems = new List<OpportunityLineItem>();

            for(ProdExcel prod : prods){
                if(m_pbe.containsKey(prod.ref + (prod.tamanho != null ? prod.tamanho : ''))){
                    PricebookEntry pbe = m_pbe.get(prod.ref + (prod.tamanho != null ? prod.tamanho : ''));
                    OpportunityLineItem newItem = new OpportunityLineItem();
                    newItem.OpportunityId = sId;
                    newItem.Codigo_de_cor__c = prod.cor;
                    newItem.PricebookEntryId = pbe.Id;
                    newItem.Tamanho__c = prod.tamanho;
                    newItem.Referencia_SKU__c = prod.ref + (prod.cor != null ? '.' +  prod.cor : '');
                    newItem.Quantity = prod.quantidade;
                    
                    //Calcular Preço
                    if(precosCliente.containsKey(pbe.Product2Id)){
                        newItem.UnitPrice = precosCliente.get(pbe.Product2Id).Valor__c;
                    }else if(acc.Escalao_Hidea__c != null){
                        newItem.UnitPrice = (Decimal) pbe.get('Preco_' + acc.Escalao_Hidea__c + '__c');
                    }else{
                        newItem.UnitPrice = 
                            c_AddProduct.calcPreco(pbe,
                                                   (opp.RecordType.DeveloperName.contains('Orcamento') ? 
                                                    prod.quantidade :
                                                    quantities.get(prod.ref + (prod.tamanho != null ? prod.tamanho : ''))));
                    }
                    newItems.add(newItem);
                }
            }
            insert newItems;
        }catch(Exception m_Exception){
            system.debug('Message -> Exception ' + m_Exception.getMessage() + ' ' + m_Exception.getLineNumber());
        }
        return null;
    }
    
    public class ProdExcel{
        public String ref;
        public String cor;
        public String tamanho;
        public Decimal quantidade;
        
        public ProdExcel(String ref, String cor, String tamanho, Decimal quantidade){
            this.ref = ref;
            this.cor = cor;
            this.tamanho = tamanho;
            this.quantidade = quantidade;
        }
        public ProdExcel(){
        }
    }
    public Pagereference BackOpportunity(){
        return pgReturnPage;
    }


}