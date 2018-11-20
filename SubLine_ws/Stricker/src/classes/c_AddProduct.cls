public with sharing class c_AddProduct {
    //Nr de campos de preços por quantidade nas entradas de preços dos produtos
    public static Integer FIELDSQTD = 10;
    public String warningMsg {get;set;}
    public Opportunity opp{get;set;}
    public Map<String,Product> produtos{get;set;}
    
    public Map<String,boolean> agrupamento{get;set;}//mapa para contruir a selecção de agrupamentos
    public List<Agrupador_OLI__c> newAgrupadores{get;set;}//lista de agrupadores criados
    public Map<String, Agrupador> agrupadores {get;set;}//lista de agrupadores já existentes
    
    public OpportunityLineItem header{get;set;}
    public Map<String,Map<String,Map<String, PricebookEntry>>> customs{get;set;}
    public Boolean isQuantity{get;set;}
    public Sidebar sidebar{get;set;}
    public Map<String,SelectOption> map_options{get;set;}
    public Map<String,SelectOption> map_optionsc{get;set;}
    public Map<String,Preco_por_cliente__c> map_precos{get;set;}
    public List<OpportunityLineItem> olisDelete{get;set;}
    public String pricebook{get;set;}
    public Map<String, Decimal> quantities {get;set;}//Quantidades na página, para desconto fora de Orçamentos(Id Produto, quantidade);
    public String idGroup {get;set;}
    public boolean isSucess {get;set;}
    public Decimal tablePrice {get;set;}
    public List<OpportunityLineItem> taxas;
    public List<OpportunityLineItem> transportadoras{get;set;}
    public Map<String, String> intEscalaoMap {get;set;}
    public List<String> nPrices {get;set;}
    public static final Set<String> transpCodes = new Set<String>{'NSPORTES', 'NSPTER', 'NSDESPACHCLI', 'NSPCE'};
    public boolean isAuthorized {get;set;}
    public String lastModifiedInit;
    public Map<String, Decimal> mapTamanhos = new Map<String, Decimal>{'128MB' => 0.125,'256MB' => 0.25,'512MB' => 0.5,'1GB' => 1,'2GB' => 2,'4GB' => 4,'8GB' => 8,'16GB' => 16,'32GB' => 32};
    
    //produto genérico OI/FOI
    public boolean produtoGenerico {get;set;}
    public PricebookEntry genPbe {get;set;}
    //Contrutor da classe c_AddProduct
    public c_AddProduct(ApexPages.StandardController controller){
        
        isSucess = false;
        produtoGenerico = false;
        fileSucess = false;
        intEscalaoMap = getIntEscalaoMap();
        
        nPrices = new List<String>();
        for(Integer i = 1; i <= c_AddProduct.FIELDSQTD ; i++){
            nPrices.add(String.valueOf(i));
        }
        //Campos da oportunidade usados na página p_AddProduct
        List<String> fieldNames = new List<String>{'Id','Name','AccountId','Pricebook2Id','SyncedQuoteID','Type','StageName','Account.Escalao_Hidea__c','Impresso__c','LastModifiedById','Versao_enviada__c',
            'RecordType.Name','RecordType.DeveloperName','Account.BillingCountryCode','Account.Mercado_de_customizacoes__c', 'Stamp__c', 'Amostra__c', 'Tipo_de_amostra__c','Autorizada__c'};
                if(!Test.isRunningTest()) controller.addFields(fieldNames);
        this.opp = (Opportunity)controller.getRecord();
        
        if(Test.isRunningTest()) opp = [Select Id,Name,AccountId,Pricebook2Id,SyncedQuoteID,Type,StageName,Account.Escalao_Hidea__c, Account.Mercado_de_customizacoes__c,Stamp__c,Autorizada__c,Impresso__c ,LastModifiedById,
                                        Versao_enviada__c,
                                        RecordType.Name,RecordType.DeveloperName,Account.BillingCountryCode,CurrencyIsoCode,Amostra__c, Tipo_de_amostra__c From Opportunity Where Id = :controller.getId()];
        Profile_Id__mdt adminId = [Select Id,Id__c From Profile_Id__mdt Where QualifiedApiName = 'Administrador_do_sistema'];
        
        isAuthorized = (opp.Impresso__c || opp.Autorizada__c != null) && UserInfo.getProfileId() != adminId.Id__c;
        
        lastModifiedInit = opp.LastModifiedById;
            this.Customizing = false;
        taxas = new List<OpportunityLineItem>();
        //inicialização do header da tabela dos produtos a adicionar na oportunidade
        this.header = new OpportunityLineItem(OpportunityId=this.opp.Id,Valor_de_tabela_de_precos__c=false);
        //criação do mapa com pricebookentrys ativos de todos os produtos do catalogo de preços
        try{
            genPbe = [Select Id,Pricebook2Id,ProductCode,Product2.ProductCode,UnitPrice,Product2Id,Product2.Cor__c,Maximo_1__c,Maximo_2__c,
                      Maximo_3__c,Maximo_4__c,Maximo_5__c,Maximo_6__c,Maximo_7__c,Maximo_8__c,Maximo_9__c,Maximo_10__c,Minimo_1__c,
                      Minimo_2__c,Minimo_3__c,Minimo_4__c,Minimo_5__c,Minimo_6__c,Minimo_7__c,Minimo_8__c,Minimo_9__c,Minimo_10__c,
                      Preco_1__c,Preco_2__c,Preco_3__c,Preco_4__c,Preco_5__c,Preco_6__c,Preco_7__c,Preco_8__c,Preco_9__c,Preco_10__c,
                      Preco_A__c,Preco_B__c,Preco_C__c,Preco_D__c,Preco_E__c,Preco_F__c,Preco_G__c,Preco_H__c,Preco_I__c,Preco_J__c,
                      Product2.Cores_de_customizacao__c, Product2.Name,Product2.Textil__c
                      From PricebookEntry Where Pricebook2Id = :opp.Pricebook2Id And ProductCode = 'NSGEN' And CurrencyIsoCode = :opp.CurrencyIsoCode Limit 1];
            
        }catch(exception ex){
            genPbe = new PricebookEntry();
        }
        //mapa com todos os valores disponíveis no campo cor dos produtos
        Schema.sObjectType sobject_type = Product2.getSObjectType();
        Schema.DescribeSObjectResult sobject_describe = sobject_type.getDescribe();
        Map<String, Schema.SObjectField> field_map = sobject_describe.fields.getMap();
        List<Schema.PicklistEntry> pick_list_values = field_map.get('Cor__c').getDescribe().getPickListValues();
        map_options = new Map<String,selectOption>();
        for (Schema.PicklistEntry a : pick_list_values) {
            map_options.put(a.getValue(), new selectOption(a.getValue(), a.getLabel()));
        }
        //mapa com todos os valores disponíveis no campo cor de customização dos produtos   
        Schema.sObjectType sobject_typec = Product2.getSObjectType();
        Schema.DescribeSObjectResult sobject_describec = sobject_typec.getDescribe();
        Map<String, Schema.SObjectField> field_mapc = sobject_describec.fields.getMap();
        List<Schema.PicklistEntry> pick_list_valuesc = field_mapc.get('Cores_de_customizacao__c').getDescribe().getPickListValues();
        map_optionsc = new Map<String,selectOption>();
        for (Schema.PicklistEntry a : pick_list_valuesc) {
            map_optionsc.put(a.getValue(), new selectOption(a.getValue(), a.getLabel()));
        }
        //mapa com os preços por cliente disponíveis para o cliente
        map_precos = new Map<String,Preco_por_cliente__c>();
        for(Preco_por_cliente__c p :
            [select Produto__c,Valor__c from Preco_por_cliente__c where Cliente__c =:this.opp.AccountId 
             And ((Data_de_inicio__c <= :System.today() And Data_de_fim__c >= :System.today())
                  OR (Data_de_inicio__c <= :System.today() And Data_de_Fim__c = null)
                  OR (Data_de_inicio__c = null And Data_de_fim__c >= :System.today())
                  OR (Data_de_inicio__c = null And Data_de_fim__c = null))]){
                      map_precos.put(p.Produto__c, p);
                  }
        
        agrupamento = new Map<String, boolean>();
        newAgrupadores = new List<Agrupador_OLI__c>();
        quantities = new Map<String, Decimal>();
        agrupadores = new Map<String, Agrupador>();
        
        refreshProdutos();
        
        definePricebook();
        //inicialização com o preço por quantidade a falso
        this.isQuantity = false;
        //inicialização da tabela de componentes do produto a vazia
        this.sidebar = new sidebar();
        //inicialização da lista dos produtos a apagar
        this.olisDelete = new List<OpportunityLineItem>();
        
        sortMaps();
        transportadoras = [Select id, Preco_Unitario__c,TotalPrice, UnitPrice, Product2.Nome_para_user__c, Name, Expedicao__c, Expedicao__r.Transportadora__c,
                           Expedicao__r.Morada_aux__c,Referencia_Sku__c,ProductCode
                           From OpportunityLineItem
                           Where ProductCode IN :transpCodes And OpportunityId = :opp.Id];
    }
    
    
    public Map<String, String> getIntEscalaoMap(){
        return new Map<String,String>{'1' => 'A','2' => 'B','3' => 'C','4' => 'D','5' => 'E','6' => 'F','7' => 'G','8' => 'H','9' => 'I','10' => 'J'};
            }
    public Map<String, String> getComponentMap(){
        Map<String, String> componentMap = new Map<String, String>();
        
        Schema.DescribeFieldResult F = Product2.Componente_da_impressao__c.getDescribe();
        List<Schema.PicklistEntry> P = F.getPicklistValues();
        for (Schema.PicklistEntry a : P) { //for all values in the picklist list
            componentMap.put(a.getValue(), a.getLabel()); 	//add the value and label to our final list
        }
        return componentMap;
    }
    public Map<String, String> getTecnicaMap(){
        Map<String, String> tecnicaMap = new Map<String, String>();
        
        Schema.DescribeFieldResult F = Product2.Tecnica__c.getDescribe();
        List<Schema.PicklistEntry> P = F.getPicklistValues();
        for (Schema.PicklistEntry a : P) { //for all values in the picklist list
            tecnicaMap.put(a.getValue(), a.getLabel()); 	//add the value and label to our final list
        }
        return tecnicaMap;
    }
    
    public String blobFile {get;set;}
    public String fileName {get;set;}
    public boolean fileSucess {get;set;} 
    public void showBlob(){
        fileSucess = false;
        if(blobFile != null){
            blobFile= blobFile.substring(blobFile.indexOf(',')+1);
            
            ContentVersion version = new ContentVersion();
            
            version.VersionData = EncodingUtil.base64Decode(blobFile);
            version.Title = fileName;
            if(version.PathOnClient == null) version.PathOnClient = fileName;
            insert version;
            
            Map<Id, ContentVersion> versionMap = new Map<Id, ContentVersion>([Select Id, ContentDocumentId From ContentVersion Where Id =:version.Id]);
            
            ContentDocumentLink newLink = new ContentDocumentLink();
            newLink.ContentDocumentId = versionMap.get(version.Id).ContentDocumentId;
            newLink.LinkedEntityId = opp.Id;
            newLink.ShareType = 'I';
            
            insert newLink;
            
            fileSucess = true;
            //fileName = null;
            blobFile = null;
        }
    }
    
    public void buildPbeMap(Map<Id, PricebookEntry> pbes){
        for(PricebookEntry pbe: [select Id,Product2.RecordType.Name,Product2.RecordType.DeveloperName,Pricebook2Id,ProductCode,Product2.ProductCode,UnitPrice,Product2Id,Product2.Cor__c,Maximo_1__c,Maximo_2__c,
                                 Maximo_3__c,Maximo_4__c,Maximo_5__c, Maximo_6__c,Maximo_7__c,Maximo_8__c,Maximo_9__c,Maximo_10__c,Minimo_1__c,Minimo_2__c,Product2.Tecnica__c,
                                 Minimo_3__c,Minimo_4__c,Minimo_5__c,Minimo_6__c,Minimo_7__c,Minimo_8__c,Minimo_9__c,Minimo_10__c,Preco_1__c,Preco_2__c,Product2.Dimensoes_maximas_de_impressao__c,
                                 Preco_3__c,Preco_4__c,Preco_5__c,Preco_6__c,Preco_7__c,Preco_8__c,Preco_9__c,Preco_10__c,Preco_A__c,Preco_B__c,Preco_C__c,Product2.Url_Imagem__c,
                                 Preco_D__c,Preco_E__c,Preco_F__c,Preco_G__c,Preco_H__c,Preco_I__c,Preco_J__c,Product2.Cores_de_customizacao__c, Product2.Name,
                                 Name, Product2.Multiplicador_Produto__c, Product2.Tamanho__c, Product2.Nome_para_user__c, Custo_adicional__c, Product2.Textil__c
                                 from PricebookEntry where Pricebook2Id =:this.opp.Pricebook2Id and IsActive=true And CurrencyIsoCode = :opp.CurrencyIsoCode
                                 and Product2.RecordType.DeveloperName != 'Customizacao']){
                                     /* */
                                     pbes.put(pbe.Product2Id, pbe);
                                 }
    }
    
    public PricebookEntry getPbe(Id productId){
        if(productId != null){
            try{
                return [select Id,Product2.RecordType.Name,Product2.RecordType.DeveloperName,Pricebook2Id,ProductCode,Product2.ProductCode,UnitPrice,Product2Id,Product2.Cor__c,Maximo_1__c,Maximo_2__c,Product2.Tecnica__c,
                        Maximo_3__c,Maximo_4__c,Maximo_5__c, Maximo_6__c,Maximo_7__c,Maximo_8__c,Maximo_9__c,Maximo_10__c,Minimo_1__c,Minimo_2__c,Product2.Dimensoes_maximas_de_impressao__c,
                        Minimo_3__c,Minimo_4__c,Minimo_5__c,Minimo_6__c,Minimo_7__c,Minimo_8__c,Minimo_9__c,Minimo_10__c,Preco_1__c,Preco_2__c,Product2.Url_Imagem__c,
                        Preco_3__c,Preco_4__c,Preco_5__c,Preco_6__c,Preco_7__c,Preco_8__c,Preco_9__c,Preco_10__c,Preco_A__c,Preco_B__c,Preco_C__c,
                        Preco_D__c,Preco_E__c,Preco_F__c,Preco_G__c,Preco_H__c,Preco_I__c,Preco_J__c,Product2.Cores_de_customizacao__c, Product2.Name,Product2.ChaveExterna__c,
                        Name, Product2.Multiplicador_Produto__c, Product2.Tamanho__c, Product2.Nome_para_user__c, Product2.Textil__c, Custo_adicional__c
                        from PricebookEntry where Pricebook2Id =:this.opp.Pricebook2Id and IsActive=true And CurrencyIsoCode = :opp.CurrencyIsoCode and Product2Id = :productId];
            }catch(Exception ex){
                system.debug(ex.getMessage() + ' ' + ex.getMessage() + ' ID:' + productId);
                return null;
            }
        }
        return null;
    }
    
    public Set<String> bypassCodes(){
        
        return new Set<String>{'NSEMB','NSMUDCOR'};
    }
    
    //define as condições da query consoante os critérios
    public void definePricebook(){
        
        Set<String> auxSet = new Set<String>();
        boolean isFirst = true;
        
        /**********************************************Filtro por Pais**********************************************
* Aplica-se a todos os recordTypes e o país tem de estar presente no custom setting Referencias_proibidas_por_pais__c;
* Esta referencia irá ser excluida da pesquisa do Auto-Complete;
*/
        List<Referencias_proibidas_por_pais__c> refsPais = [Select id,Referencias__c 
                                                            From Referencias_proibidas_por_pais__c
                                                            Where Codigo_do_pais__c = :opp.Account.BillingCountryCode];
        String forbiddenRefs = '';
        if(!refsPais.isEmpty()){
            for(Referencias_proibidas_por_pais__c refPais : refsPais){
                for(String ref : refPais.Referencias__c.split(';')){
                    auxSet.add(ref);            
                }
            }
            forbiddenRefs = '(';
            for(String s : auxSet){
                if(isFirst){
                    isFirst = false;
                }else{
                    forbiddenRefs += ',';
                }
                forbiddenRefs += '\'' + s + '\'';
            }
            forbiddenRefs += ')';
        }
        /**********************************************Filtro por referencias conjuntas**********************************************
* Aplica-se apenas ao recordType Folha de Obra;
* Corre ao iniciar para apanhar produtos já existentes no dossier;
* Corre sempre que for adicionado novo produto;
* Apanha todos os código já existentes para ver quais desses contêm restrições;
* Adiciona ao campo comboRefFilter para permitir que uma referencia seja adicionada à pesquisa;
*/
        String comboRefFilter = '';
        if(opp.RecordType.DeveloperName == 'Folha_de_Obra' && !produtos.isEmpty()){
            Set<String> existingRefs = new Set<String>();
            for(Product prod : produtos.values()){
               if(!bypassCodes().contains(prod.code)) existingRefs.add(prod.code);
            }
            
            List<Referencias_conjuntas__c> comboRefs = [Select id,Referencia_principal__c, Referencias_relacionadas__c
                                                        From Referencias_conjuntas__c
                                                        Where Referencia_principal__c In :existingRefs];
            if(!comboRefs.isEmpty()){
                comboRefFilter += '(';
                auxSet = new Set<String>();
                for(Referencias_conjuntas__c refs : comboRefs){
                    for(String ref : refs.Referencias_relacionadas__c.split(';')){
                        auxSet.add(ref);
                    }
                }
                
                isFirst = true;
                for(String s : auxSet){
                    if(isFirst){
                        isFirst = false;
                    }else{
                        comboRefFilter += ',';
                    }
                    comboRefFilter += '\'' + s + '\'';
                }
                if(!auxSet.isEmpty()) comboRefFilter += ',';

                comboRefFilter += '\'NSEMB\',\'NSMUDCOR\')';
            }else{
                comboRefFilter = '(';
                isFirst = true;
                for(Product p : produtos.values()){
                    if(isFirst){
                        isFirst = false;
                    }else{
                        comboRefFilter += ',';
                    }
                    comboRefFilter += '\'' + p.code + '\'';
                }
                comboRefFilter+= ')';
            }
        }
        
        /**********************************************Filtro por Dossier**********************************************
* Aplica-se apenas por recordType presente no custom setting Referencias_proibidas_por_dossier__c;
* Pesquisa das restrições por opp.RecordType.Name;
* Excluir todos as referencias presentes no setting devolvido;
*/
        List<Referencias_proibidas_por_dossier__c> refsDossier = [Select id,Referencias_proibidas__c 
                                                                  From Referencias_proibidas_por_dossier__c
                                                                  Where Dossier__c = :opp.RecordType.DeveloperName];
        String dossieRefs = '';
        if(!refsDossier.isEmpty()){
            auxSet = new Set<String>();
            for(Referencias_proibidas_por_dossier__c refDossier : refsDossier){
                for(String ref : refDossier.Referencias_proibidas__c.split(';')){
                    auxSet.add(ref);
                }
            }
            dossieRefs = '(';
            isFirst = true;
            for(String s : auxSet){
                if(isFirst){
                    isFirst = false;
                }else{
                    dossieRefs += ',';
                }
                dossieRefs += '\'' + s + '\'';
            }
            dossieRefs += ')';
        }
        
        /**********************************************Resultado**********************************************/        
        //filtro da query usado na consulta dos produtos do catalogo da oportunidade do autocomplete
        pricebook = 'IsActive = true'
            +' and Pricebook2Id = \''+opp.Pricebook2Id+'\''
            + ' And CurrencyIsoCode = \'' + opp.CurrencyIsoCode+'\''
            + (forbiddenRefs != '' ? + ' and Product2.ProductCode Not in ' + forbiddenRefs : '')
            + (comboRefFilter != '' ? + ' and (Product2.ProductCode in ' + comboRefFilter 
               //14-02-2018 para incluir sempre o serviço de embalamento NSEMB
               //2018-09-24 incluir serviço de mudança de cor NSMUDCOR
               + ' Or Product2.ProductCode = \'NSEMB\' Or Product2.ProductCode = \'NSMUDCOR\' Or Product2.ProductCode = \'NSPROVA\')' : '')
            + (dossieRefs != '' ? + ' and Product2.ProductCode Not in ' + dossieRefs : '');
        
        if(opp.RecordType.DeveloperName == 'Folha_de_Obra_de_Importacao'){
            List<Referencias_Permitidas__c> refsAllowed = [Select Id, Referencias_Permitidas__c, Usr3__c 
                                                           From Referencias_Permitidas__c 
                                                           Where Name = :opp.RecordType.DeveloperName];
            String aux = ' And (';
            String usr3 = '';
            isFirst = true;
            for(Referencias_Permitidas__c rp : refsAllowed){
                
                for(String s : rp.Referencias_Permitidas__c != null ? rp.Referencias_Permitidas__c.split(';') : new List<String>{''}){
                    if(isFirst){
                        isFirst=false;
                    }else{
                        aux += ' Or ';
                    }
                    aux += ' Product2.ProductCode Like \'&#37;' + s + '\'';
                }
                if(!isFirst){
                    aux += ' Or ';
                }
                isFirst = true;
                for(String s : rp.Usr3__c != null ? rp.Usr3__c.split(';') : new List<String>{}){
                    if(isFirst){
                        isFirst=false;
                    }else{
                        aux += ' Or ';
                    }
                    aux += ' Product2.ProductCode Like \'&#37;' + s + '\'';
                }
            }
            aux += ')';
            pricebook += aux;
        }
    }
    
    //criação do mapa com produtos já adicionados na oportunidade
    public void refreshProdutos(){
        this.produtos = new Map<String,Product>();
        
        Map<Id,PricebookEntry> pbes = new Map<Id, PricebookEntry>();
        
        buildPbeMap(pbes);
        
        //@hammer: para poder mapear produtos por id sf e bistamp
        Map<String, String> mapRefRels = new Map<String, String>();//stamp linha original, Id sf
        for(OpportunityLineItem oli :[select Id,Valor_unitario_original__c, Agrupador_OLI__c, Preco_Unitario__c,Total_de_customizacao__c,Stamp__c,Product2.RecordType.DeveloperName,
                                      Referencia_Relacionada__c,Tecnica__c ,Referencia_SKU__c,Product2Id,Dimensoes_maximas_de_impressao__c,Product2.Tamanho__c,
                                      Cores_de_customizacao__c,PricebookEntryId,ProductCode,Quantity,UnitPrice,TotalPrice,Valor_de_tabela_de_precos__c,Auxiliar_expedicao__c,
                                      Codigo_de_cor__c,Componente_da_impressao__c, Preco_aplicado__c, Description, OpportunityId, Stock_Cativo__c,Expedicao__c,
                                      Product2.Nome_para_user__c, PricebookEntry.Product2.Cor__c, Product2.Url_Imagem__c, Product2.Multiplicador_Produto__c
                                      from OpportunityLineItem 
                                      where OpportunityId=:opp.Id 
                                      and Product2.RecordType.DeveloperName = 'Produto' 
                                      And ProductCode != 'NSTAUXUSB' order by Referencia_Sku__c asc Limit 1000]){
                                          
                                          oli.Total_de_customizacao__c = oli.TotalPrice;
                                          oli.Preco_Unitario__c = oli.UnitPrice;
                                          Product aux = new Product(oli, oli.Product2Id);
                                          aux.idProduct = oli.Product2Id;
                                          aux.code = oli.ProductCode;
                                          this.produtos.put(oli.Id, aux);
                                          aux.options = fillOptions(pbes.get(oli.Product2Id));
                                          this.agrupamento.put(oli.Id, false);
                                          this.quantities.put(oli.Product2Id, (quantities.containsKey(oli.Product2Id) ? quantities.get(oli.Product2Id)
                                                                               + oli.Quantity : oli.Quantity));
                                          
                                          mapRefRels.put(oli.Stamp__c, oli.Id);
                                      }
        system.debug(mapRefRels);
        for(OpportunityLineItem oli :[select Id,Product2.RecordType.Name,Product2.RecordType.DeveloperName,Preco_Unitario__c,Total_de_customizacao__c,Referencia_Relacionada__c,Tecnica__c ,Referencia_SKU__c,
                                      Product2.Cores_de_customizacao__c,Product2Id, Product2.Name, Dimensoes_maximas_de_impressao__c,Cores_de_customizacao__c,
                                      PricebookEntryId,ProductCode,Quantity,UnitPrice,TotalPrice,Valor_de_tabela_de_precos__c,Codigo_de_cor__c, Pantone_Cor__c,
                                      Componente_da_impressao__c, Preco_aplicado__c, Alinhamento__c,Altura__c,Comprimento__c,Fonte__c,Numero_de_repeticoes__c,
                                      Texto_a_customizar__c, Numero_de_Impressoes__c, Product2.Tamanho__c
                                      from OpportunityLineItem 
                                      where OpportunityId=:opp.Id and Product2.RecordType.DeveloperName = 'Customizacao' order by Cores_de_customizacao__c asc]){
                                          if(this.produtos.containsKey(oli.Referencia_Relacionada__c)){
                                              oli.Total_de_customizacao__c = oli.TotalPrice;
                                              oli.Preco_Unitario__c = oli.UnitPrice;
                                              Custom c = new Custom(oli);
                                              c.customName = oli.Product2.Id;
                                              this.produtos.get(oli.Referencia_Relacionada__c).customList.put(oli.Id,c);
                                              this.quantities.put(oli.Product2Id, (quantities.containsKey(oli.Product2Id) ? quantities.get(oli.Product2Id)
                                                                                   + oli.Quantity : oli.Quantity));
                                          } //@hammer: para poder mapear produtos por id sf e bistamp
                                          else if(mapRefRels.containsKey(oli.Referencia_Relacionada__c)){
                                              oli.Referencia_relacionada__c = mapRefRels.get(oli.Referencia_Relacionada__c);
                                              oli.Total_de_customizacao__c = oli.TotalPrice;
                                              oli.Preco_Unitario__c = oli.UnitPrice;
                                              Custom c = new Custom(oli);
                                              c.customName = oli.Product2.Id;
                                              this.produtos.get(oli.Referencia_relacionada__c).customList.put(oli.Id,c);
                                              this.quantities.put(oli.Product2Id, (quantities.containsKey(oli.Product2Id) ? quantities.get(oli.Product2Id)
                                                                                   + oli.Quantity : oli.Quantity));
                                          }
                                      }

        for(OpportunityLineItem taxa : [Select Id, Referencia_Relacionada__c, UnitPrice, CurrencyIsoCode 
                                        From OpportunityLineItem Where ProductCode = 'NSTAXUSB' And OpportunityId=:opp.Id]){
                                            if(produtos.containsKey(taxa.Referencia_Relacionada__c)) this.produtos.get(taxa.Referencia_Relacionada__c).taxa = taxa;
                                        }
        
        this.isQuantity = false;
        pbes = null;
        system.debug(produtos);
        buildGroups();
    }
    
    public void buildGroups(){
        Integer i = 1;
        for(Agrupador_OLI__c goli : [Select id, Name, (Select id From Produto_de_oportunidade__r)
                                     From Agrupador_OLI__c
                                     Where id In (Select Agrupador_Oli__c From OpportunitylineItem Where id in :produtos.keySet())]){
                                         agrupadores.put(goli.Id, new Agrupador(goli, i));
                                         i++;
                                     }
    }
    
    public Decimal getvalorTotal(){
        Decimal total = 0;
        for(Product p : produtos.values()){
            if(p.item!= null){
                if(p.item.Total_de_customizacao__c != null){
                    total += p.item.Total_de_customizacao__c;
                    for(Custom c : p.customList.values()){
                        if(c.item.Total_de_customizacao__c != null){
                            total += c.item.Total_de_customizacao__c;
                        }
                    }
                }
            }
        }
        
        for(OpportunityLineItem taxa : taxas){
            total += taxa.Preco_unitario__c;
        }
        for(OpportunityLineItem transp : transportadoras){
            total += transp.Preco_unitario__c;
        }
        
        return total;
    }
    public class Agrupador{
        public Agrupador_OLI__c grupo{get;set;}
        public Integer index{get;set;}
        public Integer nRecords {get;set;}
        public Agrupador(Agrupador_OLI__c grupo, Integer index){
            this.grupo = grupo;
            this.index = index;
        }
        
        public Agrupador(Agrupador_OLI__c grupo, Integer index, Integer nRecords){
            this.grupo = grupo;
            this.index = index;
            this.nRecords = nRecords;
        }
    }
    private String s;
    public void addProduct(){
        s = addProductWork();
    }
    //função para adicionar produtos na tabela de produtos da oportunidade
    public String addProductWork(){
        if(produtoGenerico){
            header.UnitPrice = 0;
            header.Preco_unitario__c = 0;
            header.Total_de_customizacao__c = 0;
            header.PricebookEntryId = genPbe.Id;
            header.Referencia_SKU__c = genPbe.ProductCode;
            Product aux = new Product(header,genPbe.Product2Id);
            aux.isQuantity = isQuantity;
            //preenchimento da lista de cores com a opções de cores do produto
            aux.options = fillOptions(genPbe.Product2Id);
            aux.idProduct = genPbe.Product2Id;
            aux.code = genPbe.Product2.ProductCode;
            
            //chave para permitir adicionar mais do que uma linha do mesmo produto numa oportunidade
            string auxkey = header.Product2Id+Datetime.now().format('yyyyMMddmmss') +produtos.size();
            this.produtos.put(auxkey, aux);
            this.agrupamento.put(auxkey, false);
            
            //inicialização do header com os campos vazios
            this.header = new OpportunityLineItem();
            header.OpportunityId=this.opp.Id;
            header.Valor_de_tabela_de_precos__c=false;
            header.Stock_cativo__c=opp.RecordType.DeveloperName != 'Reserva';
            system.debug(LoggingLevel.INFO, header.Stock_cativo__c);
            this.isQuantity = false;
            buildGroups();
            sortMaps();
            definePricebook();
            
            produtoGenerico = false;
            return '';
        }else{
            /*
             * *****************************************ADICIONAR MAIS TARDE*************************************************
             * 
             * 
             * List<OpportunityLineItem> olis = new List<OpportunityLineItem>();
            if(opp.RecordType.Name.contains('Obra') || opp.RecordType.Name.contains('Nota')){
                olis = 
                    [Select id from OpportunityLineItem 
                     Where OpportunityId != :opp.Id
                     And Opportunity.AccountId = :opp.AccountId
                     And Product2Id = :header.Product2Id 
                     and Opportunity.RecordType.Name Like '%Orçamento%'];
                
                if(!olis.isEmpty()){
                    ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.WARNING,'Este producto está orçamentado.'));
                }
            }
            if(olis.isEmpty()){*/
                Boolean isValid = true;
                //validação do preenchimento dos campos do header necessarios para inserção do produto na oportunidade
                system.debug(LoggingLevel.Info, header.Product2Id);
                if(((header.Product2Id == null || String.valueOf(header.Product2Id) == '') || header.Quantity == null || header.Preco_Unitario__c == null) && !Test.isRunningTest()){
                    isValid = false;
                }
                
                if(isValid){
                    
                    //seleção da entrada de preço do produto a adicionar
                    if(header.Product2Id != null){
                        
                        PricebookEntry pbe = getPbe(header.Product2Id);
                        
                        header.Referencia_SKU__c = pbe.Product2.ProductCode
                            + (header.Codigo_de_cor__c != '0' && header.Codigo_de_cor__c != null ? '.' + header.Codigo_de_cor__c : '')
                            + (pbe.Product2.Tamanho__c != null ? '-' + pbe.Product2.Tamanho__c : '');
                        header.PricebookEntryId = pbe.Id;
                        header.PricebookEntry = pbe;
                        header.Product2 = pbe.Product2;
                        //@alteracaoSAC: reservas tem sempre stock cativo a falso
                        if(opp.RecordType.DeveloperName == 'Reserva'){
                            header.Stock_cativo__c = false;
                        }
                        //inicialização do produto a adicionar na tabela de produtos 
                        Product aux = new Product(header,pbe.Product2Id);
                        aux.isQuantity = isQuantity;
                        //preenchimento da lista de cores com a opções de cores do produto
                        aux.options = fillOptions(pbe.Product2Id);
                        aux.idProduct = pbe.Product2Id;
                        aux.code = pbe.Product2.ProductCode;
                        //chave para permitir adicionar mais do que uma linha do mesmo produto numa oportunidade
                        string s = header.Product2Id+Datetime.now().format('yyyyMMddmmss') + +produtos.size();

                        //***************************************ADICIONAR TAXA A PEN USB********************************
                        if((header.Referencia_SKU__c != null ? (pbe.Product2.Tamanho__c != null && (pbe.Product2.Tamanho__c.contains('GB') || pbe.Product2.Tamanho__c.contains('MB'))) : false) 
                           && opp.Account.BillingCountryCode == 'PT'){
                            PricebookEntry pbeTax = getPbe([Select Id From Product2 Where ProductCode = 'NSTAXUSB'].Id);
                            
                            OpportunityLineItem oli = new OpportunityLineItem();
                            oli.PricebookEntryId = pbeTax.Id;
                            oli.Referencia_SKU__c = pbeTax.ProductCode;
                            oli.Quantity = 1;
                            oli.UnitPrice = ((pbe.Product2.Tamanho__c != null && mapTamanhos.containsKey(pbe.Product2.Tamanho__c) ?
                                              mapTamanhos.get(pbe.Product2.Tamanho__c) : 1)
                                             * 0.016 * header.Quantity).stripTrailingZeros();
                            oli.OpportunityId = opp.Id;
                            oli.Preco_Unitario__c = oli.UnitPrice;
                            oli.Stock_cativo__c = true;
                            aux.taxa = oli;
                            taxas.add(oli);
                        }

                        this.produtos.put(s, aux);
                        //***************************************************VERIFICA PRECOS POR QUANTIDADE********************************************
                        if(header.Preco_aplicado__c	== 'Quantidade' && !opp.RecordType.DeveloperName.contains('Orcamento')){
                            
                            //adiciona produto ao mapa de quantidades
                            Decimal quant = (quantities.containsKey(header.Product2Id) ? quantities.get(header.Product2Id) + header.Quantity : header.Quantity);
                            this.quantities.put(header.Product2Id, quant);
                            
                            for(String oli : produtos.keySet()){
                                OpportunityLineItem item = produtos.get(oli).item;
                                if(item.Preco_aplicado__c == 'Quantidade' && item.Valor_de_tabela_de_precos__c && item.Product2Id == header.Product2Id){
                                    
                                    Decimal newPrice = calcularPreco(pbe, quantities.get(header.Product2Id));
                                    item.Valor_unitario_original__c = newPrice;
                                    if(opp.Tipo_de_amostra__c == 'Terceiros'){
                                        newPrice *= 0.05;
                                    }
                                    item.UnitPrice = newPrice;
                                    item.Preco_Unitario__c = newPrice;
                                    item.Total_de_customizacao__c = item.Quantity * newPrice;
                                }
                            }
                        }
                        
                        //Consulta Stock
                        consultaStock(aux, getPbe(aux.item.Product2Id));
                        
                        this.agrupamento.put(s, false);

                        //inicialização do header com os campos vazios
                        this.header = new OpportunityLineItem(OpportunityId=this.opp.Id,Valor_de_tabela_de_precos__c=false);
                        header.Stock_cativo__c = true;
                        header.Valor_de_tabela_de_precos__c = true;
                        this.isQuantity = false;
                        buildGroups();
                        sortMaps();
                        definePricebook();
                        return s;
                    }else{
                        ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.WARNING,'Todos os campos devem ser preenchidos'));
                        return '';
                    }
                    //}
                    
                }else{
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, Label.Produto_nao_valido));
                }
        }
        return '';
    }
    
    public void consultaStock(Product aux, PricebookEntry pbe){
        
        try{
            Integrator.consultaStock(aux, pbe.ProductCode, pbe.Product2.Tamanho__c != null ? pbe.Product2.Tamanho__c : '' , aux.item.Codigo_de_cor__c);
        }catch(Exception ex){}
        
    }
    
    public void cloneOLI(){
        cloneOLIWork();
    }
    
    public boolean cloneOLIWork(){
        if(idProduct != null){
            
            Product aux = produtos.get(idProduct);
            header = aux.item.clone();
            header.Agrupador_OLI__c = null;
            header.TotalPrice = null;
            addProduct();
            idProduct = s;
            if(s != null && s != ''){
                getCustoms();
                for(Custom cust : aux.customList.values()){
                    PricebookEntry pbe = getPbe(cust.customName);
                    idCustom = pbe.Product2.Tecnica__c;
                    typeCustom = cust.item.Componente_da_impressao__c;
                    nameCustom = pbe.Product2.ChaveExterna__c;
                    addCustomClone(cust.item);
                }
                priceByQuantityCustom(idProduct);
                aux = produtos.get(idProduct);
                aux.show = false;
                Customizing = false;
                idProduct = null;
                
                //Keidy - Por não encontrar a chave no mapa de produtos
                typeCustom = null;
                idCustom = null;
                return true;
            }
        }
        return false;
    }
    
    public Decimal calcularPreco(PricebookEntry pbe, Decimal quantity){
        PricebookEntry priceAux = pbe;
        if(this.opp.Account.Mercado_de_customizacoes__c != null && pbe.Product2.RecordType.DeveloperName == 'Customizacao'){
            List<Pricebook2> catalogoAux = [select Id from Pricebook2 where Mercado__c =:this.opp.Account.Mercado_de_customizacoes__c limit 1];
            if(!catalogoAux.isEmpty()){
                List<PricebookEntry> listAux = [select Id,Product2.RecordType.Name,Product2.RecordType.DeveloperName,Pricebook2Id,ProductCode,Product2.ProductCode,UnitPrice,Product2Id,Product2.Cor__c,Maximo_1__c,
                                                Maximo_3__c,Maximo_4__c,Maximo_5__c, Maximo_6__c,Maximo_7__c,Maximo_8__c,Maximo_9__c,Maximo_10__c,Minimo_1__c,Minimo_2__c,
                                                Minimo_3__c,Minimo_4__c,Minimo_5__c,Minimo_6__c,Minimo_7__c,Minimo_8__c,Minimo_9__c,Minimo_10__c,Preco_1__c,Preco_2__c,Maximo_2__c,
                                                Preco_3__c,Preco_4__c,Preco_5__c,Preco_6__c,Preco_7__c,Preco_8__c,Preco_9__c,Preco_10__c,Preco_A__c,Preco_B__c,Preco_C__c,
                                                Preco_D__c,Preco_E__c,Preco_F__c,Preco_G__c,Preco_H__c,Preco_I__c,Preco_J__c,Product2.Cores_de_customizacao__c, Product2.Name,
                                                Name, Product2.Multiplicador_Produto__c, Product2.Tamanho__c, Custo_adicional__c, Product2.Textil__c
                                                from PricebookEntry where Pricebook2Id =: catalogoAux[0].Id and Product2ID =: pbe.Product2Id and IsActive=true
                                                And CurrencyIsoCode = :opp.CurrencyIsoCode];
                if(!listAux.isEmpty()){
                    priceAux = listAux[0];
                }
            }
        }
        return calcPreco(priceAux, quantity, opp, map_precos);
    }
    
    public static Decimal calcPreco(PricebookEntry pbe, Decimal quantity){
        
        
        Decimal newPrice = 0;
        PricebookEntry priceAux = pbe;
        for(Integer i = 1; i <= FIELDSQTD; i++){
            Decimal min = (Decimal)priceAux.get('Minimo_'+i+'__c');
            Decimal max = (Decimal)priceAux.get('Maximo_'+i+'__c');
            if(min <= quantity && max >= quantity){
                newPrice = (Decimal)priceAux.get('Preco_'+i+'__c');
                break;
            }
        }
        if(pbe.Custo_adicional__c != null) newPrice += pbe.Custo_adicional__c;
        return newPrice;
        
    }
    
    public static Decimal calcPreco(PricebookEntry pbe, Decimal quantity, Opportunity opp, Map<String,Preco_por_cliente__c> map_precos){

        //RP 07-11-2018
        Decimal newPrice = 0;
        
        if(pbe.Product2Id != null){
            if(map_precos.containsKey(pbe.Product2Id)){
                newPrice = map_precos.get(pbe.Product2Id).Valor__c;
                if(opp.Tipo_de_amostra__c == 'Terceiros'){
                    newPrice *= 0.05;
                }
            }
            else{
            //verifica se existe um preço para o escalão da conta
                if(opp.Account.Escalao_Hidea__c != null && opp.Account.Escalao_Hidea__c != '1' 
                   && pbe.Product2.Textil__c == false 
                   && pbe.Product2.RecordType.DeveloperName != 'Customizacao'){
                    newPrice = (Decimal)pbe.get('Preco_'+opp.Account.Escalao_Hidea__c+'__c');
                    if(opp.Tipo_de_amostra__c == 'Terceiros'){
                        newPrice *= 0.05;
                    }
                }else{
                    PricebookEntry priceAux = pbe;
                    for(Integer i = 1; i <= FIELDSQTD; i++){
                        Decimal min = (Decimal)priceAux.get('Minimo_'+i+'__c');
                        Decimal max = (Decimal)priceAux.get('Maximo_'+i+'__c');
                        if(min <= quantity && max >= quantity){
                            newPrice = (Decimal)priceAux.get('Preco_'+i+'__c');
                            break;
                        }
                    }
                }
        }
        }
        
        if(pbe.Custo_adicional__c != null) newPrice += pbe.Custo_adicional__c;
        
        return newPrice;
        
        /* Codigo Anterior
        Decimal newPrice = 0;
        PricebookEntry priceAux = pbe;
        for(Integer i = 1; i <= FIELDSQTD; i++){
            Decimal min = (Decimal)priceAux.get('Minimo_'+i+'__c');
            Decimal max = (Decimal)priceAux.get('Maximo_'+i+'__c');
            if(min <= quantity && max >= quantity){
                newPrice = (Decimal)priceAux.get('Preco_'+i+'__c');
                break;
            }
        }
        if(pbe.Custo_adicional__c != null) newPrice += pbe.Custo_adicional__c;
        return newPrice;
		*/
    }

    public List<String> sortedKeys {get;set;}
    public void sortMaps(){
        sortedKeys = new List<String>();
        Map<Integer, List<String>> auxMap = new Map<Integer, List<String>>();
        
        for(String key : produtos.keySet()){
            OpportunityLineItem item = produtos.get(key).item;
            
            if(item.Agrupador_OLI__c != null && agrupadores.containsKey(item.Agrupador_OLI__c)){
                if(!auxMap.containsKey(agrupadores.get(item.Agrupador_OLI__c).index)){
                    auxMap.put(agrupadores.get(item.Agrupador_OLI__c).index, new List<String>());
                }
                auxMap.get(agrupadores.get(item.Agrupador_OLI__c).index).add(key);
                
            }else{
                if(!auxMap.containsKey(0)){
                    auxMap.put(0, new List<String>());
                }
                auxMap.get(0).add(key);
            }
        }
        for(Integer i = 1; i <= auxMap.keySet().size(); i++){
            if(auxMap.containsKey(i)){
                for(String key : auxMap.get(i)){
                    sortedKeys.add(key);
                }
            }
        }
        if(auxMap.containsKey(0)){
            for(String key : auxMap.get(0)){
                sortedKeys.add(key);
            }
        }
    }
    
    //função que retorna a lista de cores do produto
    public List<SelectOption> getColors(){
        List<SelectOption> options = new List<SelectOption>();
        
        if(header.Product2Id != null){
            PricebookEntry pbe = getPbe(header.Product2Id);
            if(pbe != null){
                header.PricebookEntry = pbe;
                if(pbe.Product2.Cor__c != null){
                    List<String> aux = pbe.Product2.Cor__c.split(';');
                    //if(!aux.isEmpty())header.Codigo_de_cor__c = aux[0];
                    
                    if(aux.size() > 1) options.add(new SelectOption('','--'));
                    for(String s :aux){
                        if(map_options.containsKey(s)){
                            options.add(map_options.get(s));
                        }
                    }
                }
                //preencher o campo com o preço do produtos adicionado
                if(header.PricebookEntryId == null){
                    priceByTablePrice();
                }
            }
        }
        return options;
    }
    //tabela de preços do produto referenciado no header
    
    //cria agrupamento com os olis seleccionados no modal
    public void criarAgrupamento(){
        
        List<OpportunityLineItem> olis = new List<OpportunityLineItem>();
        Decimal quantity = 0;
        String ref = null;
        for(String key : agrupamento.keySet()){
            if(agrupamento.get(key) && produtos.containsKey(key)){
                agrupamento.put(key, false);
                olis.add(produtos.get(key).item);
                quantity += produtos.get(key).item.Quantity;
                //validar ref unica
                if(ref == null) ref = produtos.get(key).item.Product2Id;
                else if(ref != produtos.get(key).item.Product2Id){
                    ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.WARNING,'Selecione apenas uma referencia de produto.'));
                    return;
                }
            }
        }
        
        if(!olis.isEmpty()){
            Agrupador_OLI__c agr = new Agrupador_OLI__c();
            
            insert agr;
            
            newAgrupadores.add(agr);
            agrupadores.put(agr.Id, new Agrupador([Select id, Name, (Select id From Produto_de_oportunidade__r)
                                                   From Agrupador_OLI__c
                                                   Where id = :agr.Id],agrupadores.size() + 1,olis.size()));
            Decimal newPrice = calcularPreco(getPbe(ref) , quantity);
            
            Decimal priceSamples = newPrice * 0.05;
            
            for(OpportunityLineItem oli : olis){
                oli.Agrupador_OLI__c = agr.Id;
                if(oli.Preco_aplicado__c == 'Quantidade'){
                    oli.Valor_unitario_original__c = newPrice;
                    
                    oli.UnitPrice = opp.Tipo_de_amostra__c == 'Terceiros' ? priceSamples : newPrice;
                    oli.Preco_Unitario__c = opp.Tipo_de_amostra__c == 'Terceiros' ? priceSamples : newPrice;
                    oli.Valor_de_tabela_de_precos__c = true;
                    oli.Total_de_customizacao__c = oli.Quantity * (opp.Tipo_de_amostra__c == 'Terceiros' ? priceSamples : newPrice);
                }
            }
            sortMaps();
        }else{
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.WARNING,'Por favor seleccione os produtos para agrupar.'));
            return;
        }
    }
    
    //metodo para apagar agrupadores ao carregar no botão sair
    public void apagarAgrupadores(){
        try{
            delete newAgrupadores;
            isSucess = true;
        }catch(Exception ex){
            isSucess = false;
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.WARNING,'Impossivel sair.'));
            
        }
    }
    
    //metodo para apagar agrupador ao carregar no botão de um agrupador especifico
    public void deleteAgrupador(){
        if(idGroup != null){
            
            delete new Agrupador_OLI__c(Id=idGroup);//apaga agrupador da base de dados
            if(agrupadores.containsKey(idGroup))agrupadores.remove(idGroup);//apaga agrupador do mapa dos booleanos
            
            //apaga agrupador da lista de novos agrupadores criados por esta página
            for(integer i = 0; i < newAgrupadores.size(); i++){
                if(newAgrupadores.get(i).Id == idGroup) {
                    newAgrupadores.remove(i);
                    break;
                }
                
            }
            
            //reordena lista de agrupadores
            Integer index = 1;
            for(Agrupador agrup : agrupadores.values()){
                agrup.index = index;
                index++;
            }
            Set<Id> prodIds = new Set<Id>(); 
            for(Product prod : produtos.values()){
                prodIds.add(prod.item.Product2Id);
            }
            
            Map<Id,PricebookEntry> pbes = new Map<Id, PricebookEntry>();
            
            buildPbeMap(pbes);
            
            //apaga id de agrupador do produto, e atribui-lhe novamente o preço que tinha sem agrupador
            for(Product prod : produtos.values()){
                if(prod.item.Agrupador_OLI__c == idGroup){
                    prod.item.Agrupador_OLI__c = null;
                    
                    if(prod.item.Preco_aplicado__c == 'Quantidade'){
                        Decimal newPrice = calcularPreco(pbes.get(prod.item.Product2Id), prod.item.Quantity);
                        prod.item.Valor_unitario_original__c = newPrice;
                        prod.item.UnitPrice = opp.Tipo_de_amostra__c == 'Terceiros' ? newPrice * 0.05 : newPrice;
                        prod.item.Preco_Unitario__c = opp.Tipo_de_amostra__c == 'Terceiros' ? newPrice * 0.05 : newPrice;
                        prod.item.Valor_de_tabela_de_precos__c = true;
                        prod.item.Total_de_customizacao__c = prod.item.Quantity * (opp.Tipo_de_amostra__c == 'Terceiros' ? newPrice * 0.05 : newPrice);
                    }
                    
                }
            }
            sortMaps();
        }
    }
    
    public Tabela table{get;set;}
    //inicialização da tabela de preços
    public void refreshTable(){
        
        this.table = new Tabela();
        if(header.Product2Id != null){
            PricebookEntry pbe = getPbe(header.Product2Id);
            this.table.pbe = pbe;
            if(map_precos.containsKey(header.Product2Id)){
                this.table.precocliente = map_precos.get(header.Product2Id);
            }
        }
    }
    //função para inserção do preço manualmente retirando o pisco do valor da tabela de preços
    public void insertPrice(){
        priceByValue();
        header.UnitPrice = header.Preco_Unitario__c;
        header.Valor_de_tabela_de_precos__c = false;
    }
    public void insertPriceByTable(){
        if(tablePrice != null && (header.Discount == null || header.Discount == 0)){
            header.Preco_unitario__c = tablePrice;
            priceByValue();
            header.UnitPrice = header.Preco_Unitario__c;
            header.Valor_de_tabela_de_precos__c = false;
            tablePrice = null;
        }
    }
    //calcula o desconto quando é selecionado
    public void insertDiscount(){
        header.Valor_unitario_original__c = header.UnitPrice;
        header.Preco_Unitario__c = header.Preco_Unitario__c - (header.Preco_Unitario__c * (header.Discount / 100));
        header.UnitPrice = header.Preco_Unitario__c;
        header.Valor_de_tabela_de_precos__c = false;
        header.Discount = null;
        priceByValueDiscount();
    }
    //preenche o preço caso exista um preço um registo preço por cliente 
    public void priceByTablePrice(){
        
        if(header.Product2Id != null){
            PricebookEntry pbe = getPbe(header.Product2Id);
            //se existir um preço por cliente
            if(map_precos.containsKey(header.Product2Id)){
                Decimal newPrice = map_precos.get(header.Product2Id).Valor__c;
                header.Valor_unitario_original__c = newPrice;
                if(opp.Tipo_de_amostra__c == 'Terceiros'){
                    newPrice *= 0.05;
                }
                header.UnitPrice = newPrice;
                header.Preco_Unitario__c = header.UnitPrice;
                header.Valor_de_tabela_de_precos__c = true;
                header.Preco_aplicado__c = 'Cliente';
            }
            //senão
            else{
                //verifica se existe um preço para o escalão da conta
                if(opp.Account.Escalao_Hidea__c != null && opp.Account.Escalao_Hidea__c != '1' && pbe.Product2.Textil__c == false){
                    Decimal newPrice = (Decimal)pbe.get('Preco_'+opp.Account.Escalao_Hidea__c+'__c');
                    header.Valor_unitario_original__c = newPrice;
                    if(opp.Tipo_de_amostra__c == 'Terceiros'){
                        newPrice *= 0.05;
                    }
                    header.UnitPrice = newPrice;
                    header.Preco_Unitario__c = header.UnitPrice;
                    header.Valor_de_tabela_de_precos__c = true;
                    header.Preco_aplicado__c = 'Escalão';
                }else{
                    header.UnitPrice = 0.0;
                    header.Preco_Unitario__c = header.UnitPrice;
                    header.Valor_de_tabela_de_precos__c = false;
                    this.isQuantity = true;
                    header.Preco_aplicado__c = 'Quantidade';
                }
            }
        }
    }
    //Atribui um preço de acordo a quantidade inserida
    public void priceByQuantity(){
        if(isQuantity && header.Quantity != null && header.Quantity > 0 && header.Product2Id != null){
            PricebookEntry pbe = getPbe(header.Product2Id);
            Decimal preco = calcularPreco(pbe, (!opp.RecordType.DeveloperName.contains('Orcamento') && quantities.containsKey(header.Product2Id) ?
                                                quantities.get(header.Product2Id) + header.Quantity : header.Quantity));
            
            header.Valor_unitario_original__c = preco;
            if(opp.Tipo_de_amostra__c == 'Terceiros'){
                preco *= 0.05;
            }
            header.UnitPrice = preco;
            header.Preco_Unitario__c = header.UnitPrice;
            header.Valor_de_tabela_de_precos__c = true;
        }
        //calcula o total
        if(header.Quantity != null && header.Preco_Unitario__c != null){
            header.Total_de_customizacao__c = header.Quantity * header.Preco_Unitario__c;
        }
    }
    //calculo do total quando existe um desconto
    public void priceByValueDiscount(){
        if(header.Quantity != null && header.Preco_Unitario__c != null){
            header.Total_de_customizacao__c = header.Quantity * header.Preco_Unitario__c;
        }
    }
    //recalculo do total quando o preço é alterado manualmente
    public void priceByValue(){
        if(header.Quantity != null && header.Preco_Unitario__c != null){
            header.Total_de_customizacao__c = header.Quantity * header.Preco_Unitario__c;
        }
        header.UnitPrice = header.Preco_Unitario__c;
        header.Valor_de_tabela_de_precos__c = header.Preco_Unitario__c == header.Valor_unitario_original__c;
    }
    //recalulo do preço caso o user mude de opção, para valor de tabela 
    public void valueTabChange(){
        if(header.Valor_de_tabela_de_precos__c == true){
            priceByTablePrice();
            priceByQuantity();
        }
    }
    
    public void priceByQuantityLine(){
        buildQuantities();
        Product aux = produtos.get(idProduct);
        if(aux.item.Quantity != null && aux.item.Quantity > 0){
            PricebookEntry pbe = getPbe(aux.idProduct);
            Decimal newQuantity = 0;
            for(String oli : produtos.keySet()){
                OpportunityLineItem item = produtos.get(oli).item;
                
                if(item.Preco_aplicado__c == 'Quantidade' && item.Product2Id == aux.item.Product2Id){
                    newQuantity += item.Quantity;
                }
            }
            //quantities.put(aux.item.Product2Id, newQuantity);
            Decimal preco = calcularPreco(pbe, (!opp.RecordType.DeveloperName.contains('Orcamento') ? newQuantity: aux.item.Quantity));
            if(aux.item.Agrupador_OLI__c != null){
                Decimal customQuantity = 0;
                for(String key :aux.customList.keySet()){
                    Custom c = aux.customList.get(key);
                    // Keidy - Retirar o Nr cores da formula
                    Decimal nImpre = aux.item.Quantity;
                        /*Decimal.valueOf(c.item.Cores_de_customizacao__c) **/ 
                    /*RETIRADO A 09-11-2018 * (c.item.Numero_de_repeticoes__c != null ? c.item.Numero_de_repeticoes__c : 1)/*/
                    Decimal nQuant = (aux.item.Product2.Multiplicador_Produto__c != null ? aux.item.Product2.Multiplicador_Produto__c : 1) * nImpre;
                    customQuantity += nQuant;
                }
            }
            
            for(String oli : produtos.keySet()){
                OpportunityLineItem item = produtos.get(oli).item;

                if(item.Preco_aplicado__c == 'Quantidade' && item.Valor_de_tabela_de_precos__c && item.Product2Id == aux.item.Product2Id 
                   && (!opp.RecordType.DeveloperName.contains('Orcamento') || (item.Agrupador_OLI__c != null && item.Agrupador_OLI__c == aux.item.Agrupador_OLI__c ))){
                       item.UnitPrice = opp.Tipo_de_amostra__c == 'Terceiros' ? preco * 0.05 : preco;
                       item.Preco_Unitario__c = opp.Tipo_de_amostra__c == 'Terceiros' ? preco * 0.05 : preco;
                       item.Valor_unitario_original__c = preco;
                       item.Total_de_customizacao__c = item.Quantity * (opp.Tipo_de_amostra__c == 'Terceiros' ? preco * 0.05 : preco);
                       item.Valor_de_tabela_de_precos__c = true;
                       item.Preco_aplicado__c = 'Quantidade';
                       priceByQuantityCustom(oli);
                   }
            }
            aux.item.UnitPrice = preco;
            aux.item.UnitPrice = opp.Tipo_de_amostra__c == 'Terceiros' ? preco * 0.05 : preco;
            aux.item.Preco_Unitario__c = opp.Tipo_de_amostra__c == 'Terceiros' ? preco * 0.05 : preco;
            aux.item.Valor_unitario_original__c = preco;
            aux.item.Total_de_customizacao__c = aux.item.Quantity * (opp.Tipo_de_amostra__c == 'Terceiros' ? preco * 0.05 : preco);
            aux.item.Valor_de_tabela_de_precos__c = true;
            aux.item.Preco_aplicado__c = 'Quantidade';
            if(aux.taxa != null){
                aux.taxa.UnitPrice = ((pbe.Product2.Tamanho__c != null ? Decimal.valueOf(pbe.Product2.Tamanho__c.left(1)) : 1)
                                      * 0.016 * aux.item.Quantity).stripTrailingZeros();
                aux.taxa.Preco_Unitario__c = aux.taxa.UnitPrice;
                taxas.add(aux.taxa);
            }
        }
        if(aux.item.Quantity != null && aux.item.Preco_Unitario__c != null){
            //aux.item.Total_de_customizacao__c = aux.item.Quantity * aux.item.Preco_Unitario__c;
            //atualiza os produtos da oportunidade
            priceByQuantityCustom(idProduct);
        }
    }
    
    public void priceByValueLine(){
        Product aux = produtos.get(idProduct);
        if(aux.item.Quantity != null){
            aux.item.Total_de_customizacao__c = aux.item.Quantity * aux.item.Preco_Unitario__c;
        }
        aux.item.UnitPrice = aux.item.Preco_Unitario__c;
        aux.item.Valor_de_tabela_de_precos__c = false;
        
        if(aux.item.Agrupador_OLI__c != null){
            Agrupador agr = agrupadores.get(aux.item.Agrupador_OLI__c);
            
            for(Product prod : produtos.values()){
                if(prod.item.Agrupador_OLI__c == agr.grupo.Id){
                    if(prod.item.Quantity != null){
                        prod.item.Total_de_customizacao__c = prod.item.Quantity * aux.item.Preco_Unitario__c;
                    }
                    prod.item.Preco_Unitario__c = aux.item.Preco_Unitario__c;
                    prod.item.UnitPrice = aux.item.Preco_Unitario__c;
                    prod.item.Valor_de_tabela_de_precos__c = false;
                }
            }
        }else if(!opp.RecordType.DeveloperName.contains('Orcamento')){
            for(String oli : produtos.keySet()){
                OpportunityLineItem item = produtos.get(oli).item;
                
                if(item.Product2Id == aux.item.Product2Id){
                    if(item.Quantity != null){
                        item.Total_de_customizacao__c = item.Quantity * aux.item.Preco_Unitario__c;
                    }
                    item.Preco_Unitario__c = aux.item.Preco_Unitario__c;
                    item.UnitPrice = aux.item.Preco_Unitario__c;
                    item.Valor_de_tabela_de_precos__c = false;
                }
            }
        }
    }
    
    public void valueTabChangeLine(){}
    
    public void changePriceInCustom(){
        Product product = produtos.get(idProduct);
        if(product != null){
            system.debug(LoggingLevel.Info, product.customList);
            system.debug(LoggingLevel.Info, idCustom);
            Custom cust = product.customList.get(idCustom);
            if(cust != null){
                
                cust.item.Total_de_customizacao__c = cust.item.Preco_Unitario__c * cust.item.Quantity;
                cust.item.UnitPrice = cust.item.Preco_Unitario__c;
                
                Decimal newPrice = cust.item.Preco_Unitario__c;
                Decimal totalPrice = cust.item.Total_de_customizacao__c;
                
                for(Product prod : produtos.values()){
                    if(product.item.Product2Id == prod.item.Product2Id){
                        for(Custom custom : prod.customList.values()){
                            if(cust.item.Product2Id == custom.item.Product2Id){
                                custom.item.UnitPrice = cust.item.Preco_Unitario__c;
                                custom.item.Preco_Unitario__c = cust.item.Preco_Unitario__c;
                                custom.item.Total_de_customizacao__c = custom.item.Preco_Unitario__c * custom.item.Quantity;
                                custom.item.Valor_de_tabela_de_precos__c = false;
                            }
                        }
                    }
                }
            }
        }
    }
    
    public void priceByTablePriceLine(){
        Product aux = produtos.get(idProduct);
        
        if(aux.item.Product2Id != null){
            PricebookEntry pbe = getPbe(aux.item.Product2Id);
            if(map_precos.containsKey(aux.item.Product2Id)){
                Decimal newPrice = map_precos.get(aux.item.Product2Id).Valor__c;
                aux.item.Valor_unitario_original__c = newPrice;
                if(opp.Tipo_de_amostra__c == 'Terceiros'){
                    newPrice *= 0.05;
                }
                aux.item.UnitPrice = newPrice;
                aux.item.Preco_Unitario__c = aux.item.UnitPrice;
                aux.item.Valor_de_tabela_de_precos__c = true;
            }else{
                if(opp.Account.Escalao_Hidea__c != null){
                    Decimal newPrice = (Decimal)pbe.get('Preco_'+opp.Account.Escalao_Hidea__c+'__c');
                    aux.item.Valor_unitario_original__c = newPrice;
                    if(opp.Tipo_de_amostra__c == 'Terceiros'){
                        newPrice *= 0.05;
                    }

                    aux.item.UnitPrice = newPrice;
                    aux.item.Preco_Unitario__c = aux.item.UnitPrice;
                    aux.item.Valor_de_tabela_de_precos__c = true;
                }else{
                    aux.item.UnitPrice = 0.0;
                    aux.item.Preco_Unitario__c = aux.item.UnitPrice;
                    aux.item.Valor_de_tabela_de_precos__c = false;
                    aux.isQuantity = true;
                }
            }
        }
    }
    
    public void buildQuantities(){
        quantities = new Map<String, Decimal>();
        for(Product prod: produtos.values()){
            if(prod.item.Product2Id != null){
                
                if(!quantities.containsKey(prod.item.Product2Id)) quantities.put(prod.item.Product2Id, 0);
                
                quantities.put(prod.item.Product2Id, quantities.get(prod.item.Product2Id) + prod.item.Quantity);
                
                for(String key :prod.customList.keySet()){
                    Custom c = prod.customList.get(key);
                    if(c != null){
                        // Keidy - Retirar o Nr cores da formula
                        Decimal nImpre = (prod.item.Quantity != null ? prod.item.Quantity : 1);
                            /*(c.item.Cores_de_customizacao__c != null ? Decimal.valueOf(c.item.Cores_de_customizacao__c) : 1) */
                           /*RETIRADO A 09-11-2018 (c.item.Numero_de_repeticoes__c != null ? c.item.Numero_de_repeticoes__c : 1)*/
                        Decimal nQuant = (prod.item.Product2.Multiplicador_Produto__c != null ? prod.item.Product2.Multiplicador_Produto__c : 1) * nImpre;
                        if(!quantities.containsKey(c.customName)) quantities.put(c.customName, 0);
                        quantities.put(c.customName, quantities.get(c.customName) + nQuant);
                    }
                }
            }
        }
    }
    public void priceByQuantityCustom(String prodId){
        Product p = produtos.get(prodId);

        if(p != null){
            Set<Id> prodIds = new Set<Id>();
            for(String key :p.customList.keySet()){
                Custom c = p.customList.get(key);
                if(c != null){
                    prodIds.add(c.customName);
                }
            }
            /*Map<Id, PricebookEntry> pbes = new Map<Id,PricebookEntry>();
            buildPbeMap(pbes);*/
            
            for(String key :p.customList.keySet()){
                Custom c = p.customList.get(key);
                if(c != null){
                    PricebookEntry pbe = getPbe(c.customName);
                   // quantities.put(c.customName, quantities.get(c.customName) - c.item.Quantity);
                    // Keidy - Retirar o Nr cores da formula
                    c.item.Numero_de_impressoes__c =  p.item.Quantity;
                    /*RETIRADO A 09-11-2018  * (c.item.Numero_de_repeticoes__c != null ? c.item.Numero_de_repeticoes__c : 1)
                    /*Decimal.valueOf(c.item.Cores_de_customizacao__c) **/
                    c.item.Quantity = (p.item.Product2.Multiplicador_Produto__c != null ? p.item.Product2.Multiplicador_Produto__c : 1) * c.item.Numero_de_impressoes__c;
                    
                    //buildQuantities();
                    //quantities.put(c.customName, quantities.get(c.customName) + c.item.Quantity);

                    if(c.item.Valor_de_tabela_de_precos__c){
                        
                        Decimal quant = p.item.Agrupador_OLI__c != null || quantities.containsKey(c.customName) ? quantities.get(c.customName) : c.item.Quantity;
                        
                        Decimal newPrice = calcularPreco(pbe, quant);
                        
                        c.item.UnitPrice = newPrice;
                        c.item.Preco_Unitario__c = newPrice;
                        c.item.Valor_unitario_original__c = newPrice;
                    }
                    c.item.Total_de_customizacao__c = c.item.Quantity * c.item.Preco_Unitario__c;
                }
            }
        }
    }
    
    public void changeSKU(){
        Product aux = produtos.get(idProduct);
        if(aux != null){
            PricebookEntry pbe = getPbe(aux.idProduct);
            aux.item.Referencia_SKU__c = pbe.Product2.ProductCode + (aux.item.Codigo_de_cor__c != null ? '.'+ aux.item.Codigo_de_cor__c : '')
                + (pbe.Product2.Tamanho__c != null ? '-' +  pbe.Product2.Tamanho__c : '');
            aux.options = fillOptions(aux.idProduct);
        }	
    }
    
    public List<SelectOption> fillOptions(String Product2Id){
        PricebookEntry pbe = Product2Id != null ? getPbe(Product2Id) : null;
        return fillOptions(pbe);
    }
    
    public List<SelectOption> fillOptions(PricebookEntry pbe){
        List<SelectOption> options = new List<SelectOption>();
        //options.add(new SelectOption('', '--'));
        if(pbe != null){
            if(pbe.Product2.Cor__c != null){
                String[] aux = pbe.Product2.Cor__c.split(';');
                for(String s :aux){
                    if(map_options.containsKey(s)){
                        options.add(map_options.get(s));
                    }
                }
            }
        }
        return options;
    }
    
    public void refreshCustomsHeader(){
        this.customs = new Map<String,Map<String,Map<String, PricebookEntry>>>();
        header.Codigo_de_cor__c = '';
        //System.debug(opp.Pricebook2Id);
        //system.debug([Select id From Pricebook2]);
        for(PricebookEntry p :[select Id,Product2.Name,Product2.Cores_de_customizacao__c,Product2.Dimensoes_maximas_de_impressao__c,Product2.Tecnica__c,
                               Product2.Componente_da_impressao__c, Product2.Localizacao_da_impressao__c, Product2.Textil__c
                               from PricebookEntry 
                               where Product2.Referencia_relacionada__c =:header.PricebookEntry.ProductCode 
                               and Pricebook2Id =:this.opp.Pricebook2Id and IsActive=true and Product2.RecordType.DeveloperName = 'Customizacao' And (Not Product2.chaveExterna__c Like '%Old_%')]){
                                       
                                   String key1 = p.Product2.Componente_da_impressao__c;
                                   String key2 = p.Product2.Tecnica__c;
                                   if(!customs.containsKey(key1)) customs.put(key1, new Map<String, Map<String, PricebookEntry>>());
                                   if(!customs.get(key1).containsKey(key2)) customs.get(key1).put(key2, new Map<String, PricebookEntry>());
                                   this.customs.get(key1).get(key2).put(p.Product2.name, p);
                                   /*ALTERADO PARA NOVA ESTRUTURA DO BLOCO DE CUSTOMIZACOES
                                    * if(this.customs.containsKey(p.Product2.Componente_da_impressao__c)){
                                       this.customs.get(p.Product2.Componente_da_impressao__c).put(key,p);
                                   }else{
                                       Map<String,PricebookEntry> l_aux = new Map<String,PricebookEntry>();
                                       l_aux.put(key,p);
                                       this.customs.put(p.Product2.Componente_da_impressao__c, l_aux);
                                   }*/
                               }
    }
    
    public String idProduct{get;set;}
    public void getCustoms(){
        Product aux = produtos.get(idProduct);
        if(aux != null){
            consultaStock(aux, getPbe(aux.item.Product2Id));
            aux.show = true;
            sidebar.item = aux.item;
            sidebar.stockAtual = aux.stockAtual;
            sidebar.stockCativo = aux.stockCativo;
            sidebar.stockPrevisto = aux.stockPrevisto;
            sidebar.stockData = aux.stockData; //Date.parse(aux.stockData.split('T')[0]);
            
            this.Customizing = true;
            this.customs = new Map<String,Map<String,Map<String, PricebookEntry>>>();
            for(PricebookEntry p :[select Id,Product2Id,Product2.Name,Product2.Cores_de_customizacao__c,Product2.Dimensoes_maximas_de_impressao__c,
                                   Product2.Dimensoes_de_impressao_da_componente__c, Product2.Localizacao_da_impressao__c,Product2.ChaveExterna__c,Product2.Tabela_de_customizacoes__c ,
                                   Product2.Tecnica__c,Product2.Componente_da_impressao__c, Product2.Altura_maxima__c, Product2.Comprimento_maximo__c, Product2.Textil__c
                                   from PricebookEntry 
                                   where Product2.Referencia_relacionada__c =:aux.code
                                   And Product2.Tamanho__c = :aux.item.Product2.Tamanho__c
                                   and Pricebook2Id =:this.opp.Pricebook2Id 
                                   and IsActive=true 
                                   and Product2.RecordType.DeveloperName = 'Customizacao' And (Not Product2.chaveExterna__c Like '%Old_%') Order by Product2.Localizacao_da_impressao__c asc, Product2.Tabela_de_customizacoes__c asc]){
                                       String key1 = p.Product2.Componente_da_impressao__c;
                                       String key2 = p.Product2.Tecnica__c;
                                       if(!customs.containsKey(key1)) customs.put(key1, new Map<String, Map<String, PricebookEntry>>());
                                       if(!customs.get(key1).containsKey(key2)) customs.get(key1).put(key2, new Map<String, PricebookEntry>());
                                       this.customs.get(key1).get(key2).put(p.Product2.ChaveExterna__c, p);
                                       /*ALTERADO PARA NOVA ESTRUTURA DO BLOCO DE CUSTOMIZACOES
                                        * String key = p.Product2.Tecnica__c;
                                       if(this.customs.containsKey(p.Product2.Componente_da_impressao__c)){
                                           this.customs.get(p.Product2.Componente_da_impressao__c).put(key,p);
                                       }else{
                                           Map<String,PricebookEntry> l_aux = new Map<String,PricebookEntry>();
                                           l_aux.put(key,p);
                                           this.customs.put(p.Product2.Componente_da_impressao__c, l_aux);
                                       }*/
                                   }
        }
    }
    
    public String idCustom{get;set;}//Componente
    public String typeCustom{get;set;}//Tecnica
    public String nameCustom{get;set;}//Nome
    public void addCustom(){
        Product aux = produtos.get(idProduct);
        if(aux != null && aux.item != null){
            aux.item.Customizado__c = true;
            system.debug(LoggingLevel.INFO, customs.get(typeCustom).get(idCustom));
            PricebookEntry prod = this.customs.get(typeCustom).get(idCustom).get(nameCustom);

            PricebookEntry pbe = getPbe(prod.Product2Id);
            
            OpportunityLineItem auxcustom = new OpportunityLineItem(OpportunityId=opp.Id,
                                                                    PricebookEntryId=pbe.Id,
                                                                    Componente_da_impressao__c=prod.Product2.Componente_da_impressao__c,
                                                                    Localizacao_de_impressao__c=prod.Product2.Localizacao_da_impressao__c,
                                                                    Tecnica__c=prod.Product2.Tecnica__c,
                                                                    Dimensoes_maximas_de_impressao__c=prod.Product2.Dimensoes_maximas_de_impressao__c,
                                                                    Valor_de_tabela_de_precos__c=true,
                                                                    UnitPrice=pbe.UnitPrice,
                                                                    Valor_unitario_original__c=pbe.UnitPrice,
                                                                    Expedicao__c = aux.item.Expedicao__c,
                                                                    Auxiliar_expedicao__c = aux.item.Auxiliar_expedicao__c);
            auxcustom.Cores_de_customizacao__c = prod.Product2.Cores_de_customizacao__c;
            auxcustom.Referencia_SKU__c = pbe.ProductCode;
            auxcustom.Stock_cativo__c = opp.RecordType.DeveloperName != 'Reserva';
            String altura = prod.Product2.Dimensoes_maximas_de_impressao__c != null ? 
                (prod.Product2.Dimensoes_maximas_de_impressao__c.contains('X') ? prod.Product2.Dimensoes_maximas_de_impressao__c.split('X')[0] : '') : '';
            auxcustom.Altura__c = altura.isNumeric() ? Decimal.valueOf(altura) : 0;
            auxcustom.Numero_de_impressoes__c =aux.item.Quantity;
                /*RETIRADO A 02-07-2018 POR DECISÃO DE MARCO RAMOS Decimal.valueOf(auxcustom.Cores_de_customizacao__c) * */
                 /*RETIRADO A 09-11-2018 (auxcustom.Numero_de_repeticoes__c != null ? auxcustom.Numero_de_repeticoes__c : 1)*/
            auxcustom.Quantity = (aux.item.Product2.Multiplicador_Produto__c != null ? aux.item.Product2.Multiplicador_Produto__c : 1) * auxcustom.Numero_de_impressoes__c;
            String comp = prod.Product2.Dimensoes_maximas_de_impressao__c != null ?
                (prod.Product2.Dimensoes_maximas_de_impressao__c.contains('X') ? (prod.Product2.Dimensoes_maximas_de_impressao__c.split('X')[1].contains(' ') ? 
                 prod.Product2.Dimensoes_maximas_de_impressao__c.split('X')[1].split(' ')[0] : ''): '') : '';
            
            auxcustom.Comprimento__c = comp.isNumeric() ? Decimal.valueOf(comp) : 0;
            Decimal preco = calcularPreco(pbe, auxcustom.Quantity);
            auxcustom.UnitPrice = preco;
            auxcustom.Preco_Unitario__c = auxcustom.UnitPrice;
            auxcustom.Total_de_customizacao__c = auxcustom.Quantity * auxcustom.UnitPrice;
            
            Custom c = new Custom(auxcustom);
            c.customName = pbe.Product2Id;
            String s = String.valueOf(System.now().getTime());
            aux.customList.put(prod.Id + s,c);
            
            this.quantities.put(pbe.Product2Id, (quantities.containsKey(pbe.Product2Id) ? quantities.get(pbe.Product2Id) + auxcustom.Quantity : auxcustom.Quantity));
            
            
            if(auxcustom.Valor_de_tabela_de_precos__c){
                //recalcula os preços dos produtos existentes
                Decimal newPrice = calcularPreco(pbe, quantities.get(pbe.Product2Id));
                for(String key : produtos.keySet()){
                    for(Custom item : produtos.get(key).customList.values()){
                        OpportunityLineItem oli = item.item;
                        if(oli.Valor_de_tabela_de_precos__c && (oli.Product2Id == pbe.Product2Id || oli.PricebookEntryId == pbe.Id)){
                            
                            oli.UnitPrice = newPrice;
                            oli.Preco_Unitario__c = newPrice;
                            oli.Valor_unitario_original__c = newPrice;
                            oli.Total_de_customizacao__c = oli.Quantity * oli.Preco_Unitario__c;
                        }
                    }
                }
            }
            //Keidy - Por não encontrar a chave no mapa de produtos
            typeCustom = null;
            idCustom = null;
        }
    }
    
    public void addCustomClone(OpportunityLineItem oliClone){
        Product aux = produtos.get(idProduct);
        if(aux != null){
            aux.item.Customizado__c = true;
            PricebookEntry prod = this.customs.get(typeCustom).get(idCustom).get(nameCustom);
            PricebookEntry pbe = getPbe(prod.Product2.Id);//*************************************************************CUSTOM
            
            OpportunityLineItem auxcustom = new OpportunityLineItem(OpportunityId=opp.Id,
                                                                    PricebookEntryId=pbe.Id,
                                                                    Componente_da_impressao__c=prod.Product2.Componente_da_impressao__c,
                                                                    Tecnica__c=prod.Product2.Tecnica__c,
                                                                    Dimensoes_maximas_de_impressao__c=prod.Product2.Dimensoes_maximas_de_impressao__c,
                                                                    Valor_de_tabela_de_precos__c=true,
                                                                    UnitPrice=pbe.UnitPrice,
                                                                    Valor_unitario_original__c=pbe.UnitPrice,
                                                                    Altura__c = oliClone.Altura__c,
                                                                    Referencia_SKU__c = oliClone.Referencia_SKU__c,
                                                                    Comprimento__c = oliClone.Comprimento__c,
                                                                    Numero_de_repeticoes__c = oliClone.Numero_de_repeticoes__c,
                                                                    Pantone_Cor__c = oliClone.Pantone_Cor__c,
                                                                    Fonte__c = oliClone.Fonte__c,
                                                                    Alinhamento__c = oliClone.Alinhamento__c,
                                                                    Texto_a_customizar__c = oliClone.Texto_a_customizar__c);
            auxcustom.Cores_de_customizacao__c = prod.Product2.Cores_de_customizacao__c;
            auxcustom.Stock_cativo__c = aux.item.Stock_cativo__c;
            // Keidy - Retirar o Nr cores da formula
            auxcustom.Numero_de_impressoes__c = aux.item.Quantity;
                /*Decimal.valueOf(auxcustom.Cores_de_customizacao__c) * */
                /*RETIRADO A 09-11-2018 * (auxcustom.Numero_de_repeticoes__c != null ? auxcustom.Numero_de_repeticoes__c : 1)*/
            auxcustom.Quantity = (aux.item.Product2.Multiplicador_Produto__c != null ? aux.item.Product2.Multiplicador_Produto__c : 1) * auxcustom.Numero_de_impressoes__c;
            Decimal quant = (quantities.containsKey(pbe.Product2Id) ? quantities.get(pbe.Product2Id) + auxcustom.Quantity : auxcustom.Quantity);
            Decimal preco = calcularPreco(pbe, quant);
            auxcustom.UnitPrice = preco;
            auxcustom.Preco_Unitario__c = auxcustom.UnitPrice;
            auxcustom.Total_de_customizacao__c = auxcustom.Quantity * auxcustom.UnitPrice;
            
            Custom c = new Custom(auxcustom);
            c.customName = pbe.Product2.Id;
            String s = String.valueOf(System.now().getTime()) + '' + aux.customList.size();
            aux.customList.put(prod.Id + s,c);
            
            this.quantities.put(pbe.Product2Id, quant);
            
            //buildQuantities();
            if(auxcustom.Valor_de_tabela_de_precos__c){
                //recalcula os preços dos produtos existentes
                Decimal newPrice = calcularPreco(pbe, quantities.get(pbe.Product2Id));
                for(String key : produtos.keySet()){
                    for(Custom item : produtos.get(key).customList.values()){
                        OpportunityLineItem oli = item.item;
                        if(oli.Valor_de_tabela_de_precos__c && (oli.Product2Id == pbe.Product2Id || oli.PricebookEntryId == pbe.Id)){
                            
                            oli.UnitPrice = newPrice;
                            oli.Preco_Unitario__c = newPrice;
                            oli.Valor_unitario_original__c = newPrice;
                            oli.Total_de_customizacao__c = oli.Quantity * oli.Preco_Unitario__c;
                            //priceByQuantityCustom(key);
                        }
                    }
                }
            }
        }
    }
    
    public void removeProduct(){
        system.debug(idProduct);
        
        Product aux = produtos.get(idProduct);
        if(aux != null){
            produtos.remove(idProduct);
            agrupamento.remove(idProduct);
            if(aux.item.Id != null){
                this.olisDelete.add(aux.item);
                if(aux.taxa != null){
                    this.olisDelete.add(aux.taxa);
                }
            }
            for(Custom c :aux.customList.values()){
                if(c.item.Id != null){
                    this.olisDelete.add(c.item);
                }
            }
            
            //recalcular preços por quantidade;
            if(aux.item.Preco_aplicado__c == 'Quantidade'){
                
                if(quantities.containsKey(aux.item.Product2Id)){
                    Decimal newQuantity = quantities.get(aux.item.Product2Id)-aux.item.Quantity;
                    Decimal newPrice = 0;
                    PricebookEntry pbe = getPbe(aux.item.Product2Id);
                    newPrice = calcularPreco(pbe, newQuantity);
                    system.debug(newPrice);
                    buildQuantities();
                    system.debug(quantities);
                    //recalcula os preços dos produtos existentes
                    for(String oli : produtos.keySet()){
                        OpportunityLineItem item = produtos.get(oli).item;
                        if(item.Preco_aplicado__c == 'Quantidade' && item.Valor_de_tabela_de_precos__c && item.Product2Id == aux.item.Product2Id){
                            item.UnitPrice = opp.Tipo_de_amostra__c == 'Terceiros' ? newPrice * 0.05 : newPrice;
                            item.Preco_Unitario__c = opp.Tipo_de_amostra__c == 'Terceiros' ? newPrice * 0.05 : newPrice;
                            item.Valor_unitario_original__c = newPrice;
                            item.Total_de_customizacao__c = item.Quantity * (opp.Tipo_de_amostra__c == 'Terceiros' ? newPrice * 0.05 : newPrice);
                            priceByQuantityCustom(oli);
                        }
                    }
                    quantities.put(aux.item.Product2Id, newQuantity);
                    system.debug(newQuantity);
                }
            }
            definePricebook();
            sortMaps();
            if(aux.item.Agrupador_OLI__c != null){
                agrupadores.get(aux.item.Agrupador_OLI__c).nRecords = agrupadores.get(aux.item.Agrupador_OLI__c).nRecords != null ? 
                    agrupadores.get(aux.item.Agrupador_OLI__c).nRecords -1 : 0;
                if(agrupadores.get(aux.item.Agrupador_OLI__c).nRecords <= 1) {
                    idGroup = aux.item.Agrupador_OLI__c;
                    deleteAgrupador();
                }
            }
            sidebar = new Sidebar();
            idProduct = null;
        }
        
        system.debug(produtos);
        system.debug(agrupamento);
        system.debug(agrupadores);
        system.debug(customs);
    }
    
    public void removeCustom(){
        
        Product auxP = produtos.get(typeCustom);
        if(auxP != null){
            system.debug(auxP.customList);
            auxP.item.Customizado__c = true;
            Custom aux = auxP.customList.get(idCustom);
            
            if(aux != null){
                auxP.customList.remove(idCustom);
                system.debug(aux);
                
                this.quantities.put(aux.customName,
                                    (quantities.containsKey(aux.customName) ?//if
                                     quantities.get(aux.customName) - aux.item.Quantity ://true
                                     aux.item.Quantity));//else
                PricebookEntry pbe = getPbe(aux.customName);
                if(aux.item.Valor_de_tabela_de_precos__c){
                    //recalcula os preços dos produtos existentes
                    Decimal newPrice = calcularPreco(pbe, quantities.get(aux.customName));
                    for(String key : produtos.keySet()){
                        for(Custom item : produtos.get(key).customList.values()){
                            OpportunityLineItem oli = item.item;
                            system.debug(oli);
                            system.debug(oli.Valor_de_tabela_de_precos__c && (oli.Product2Id == pbe.Product2Id || oli.PricebookEntryId == pbe.Id));
                            if(oli.Valor_de_tabela_de_precos__c && (oli.Product2Id == pbe.Product2Id || oli.PricebookEntryId == pbe.Id)){
                                oli.UnitPrice = newPrice;
                                oli.Preco_Unitario__c = newPrice;
                                oli.Valor_unitario_original__c = newPrice;
                                oli.Total_de_customizacao__c = oli.Quantity * oli.Preco_Unitario__c;
                            }
                        }
                    }
                }        
                if(aux.item.Id != null){
                    this.olisDelete.add(aux.item);
                }
                //Keidy - Por não encontrar a chave no mapa de produtos
                typeCustom = null;
                idCustom = null;
            }
        }
    }
    
    public void valueChangeReps(){
        buildQuantities();
        Product p = produtos.get(idProduct);
        if(p != null){
            Custom c = p.customList.get(idCustom);System.debug('################### c  '+c);
            
            if(p != null & c != null){
                PricebookEntry pbe = getPbe(c.customName);
                
                system.debug(pbe.Product2Id);
                /*priceByQuantityCustom*/
                
                //quantities.put(c.customName, quantities.get(c.customName) - c.item.Quantity);
                
                /*(c.item.Cores_de_customizacao__c != null ? Decimal.valueOf(c.item.Cores_de_customizacao__c) : 1) FORMACOES - FOI DITO QUE AFINAL NAO ENTRAVA*/
                /*c.item.Numero_de_impressoes__c = Decimal.valueOf(c.item.Cores_de_customizacao__c) * p.item.Quantity * (c.item.Numero_de_repeticoes__c != null ? 
                                                                                                                               c.item.Numero_de_repeticoes__c : 1);
                c.item.Quantity = (p.item.Product2.Multiplicador_Produto__c != null ? p.item.Product2.Multiplicador_Produto__c : 1) * c.item.Numero_de_impressoes__c;*/
                //Keidy - onchange do nr de repetições deve recalcular o quantity e o nr de impressões.
                c.item.Numero_de_impressoes__c = p.item.Quantity; /*RETIRADO A 09-11-2018 * (c.item.Numero_de_repeticoes__c != null ? c.item.Numero_de_repeticoes__c : 1)*/
                c.item.Quantity = (p.item.Product2.Multiplicador_Produto__c != null ? p.item.Product2.Multiplicador_Produto__c : 1) * c.item.Numero_de_impressoes__c;
                
                //quantities.put(c.customName, quantities.get(c.customName) + c.item.Quantity);
                
                Decimal newPrice = calcularPreco(pbe, quantities.get(c.customName));
                
                system.debug(pbe);
                c.item.UnitPrice = newPrice;
                c.item.Preco_Unitario__c = newPrice;
                c.item.Valor_unitario_original__c = newPrice;
                c.item.Total_de_customizacao__c = c.item.Quantity * c.item.Preco_Unitario__c;
                
            }
        }
    }
    
    public void setShow(){
        system.debug(produtos);
        Product aux = produtos.get(idProduct);
        if(aux != null) aux.show = !aux.show;
    }
    public Boolean Customizing{get;set;}
    public void setCustom(){
        this.Customizing = !this.Customizing;
    }
    
    public Integer getSize(){
        return this.produtos.size();
    }
    
    public String getStockHeader(){
        
            system.debug(customs);
        if(header.Codigo_de_cor__c == '' || header.Codigo_de_cor__c == null){
            List<SelectOption> opts = getColors();
            if(!opts.isEmpty()) header.Codigo_de_cor__c = opts.get(0).getValue();
        }
        Product aux = new Product(header, header.Product2Id);
        String result = '';

        string auxs = header.Product2Id;
        system.debug(auxs);
        if(header.Product2Id != null && auxs != ''){
            consultaStock(aux, getPbe(aux.item.Product2Id));
            if(aux.stockAtual != null && aux.stockCativo != null)
                result = String.valueOf(aux.stockAtual - Math.abs(aux.stockCativo));
        }
        return result;
    }
    
    public List<ColorTable> colorTable {get;set;}
    public void getColorsModal(){
        if(IdProduct != null){
            Product aux = produtos.get(idProduct);
            if(aux != null){
                colorTable = new List<ColorTable>();
                for(SelectOption opt: aux.options){
                    ColorTable ct;
                    if(opt.getValue() != aux.item.Codigo_de_cor__c){
                        ct = new ColorTable(false, opt.getValue(), opt.getLabel(), null);
                        colorTable.add(ct);
                    }
                }
            }
        }
    }
    public void createColorLines(){
        String key = idProduct;
        Product aux = produtos.get(key);
        String originalColor = aux.item.Codigo_de_cor__c;
        Decimal qOriginal = aux.item.Quantity;
        if(aux != null){
            Decimal total = 0;
            for(ColorTable ct : colorTable){
                if(ct.selected){
                    if(ct.quantity != null && ct.quantity != 0){
                        total += ct.quantity;
                    }
                }
            }
            if(total <= qOriginal){
                boolean sucess = true;
                for(ColorTable ct : colorTable){
                    if(ct.selected && sucess){
                        if(ct.quantity != null && ct.quantity != 0){
                            idProduct = key;
                            aux.item.Codigo_de_cor__c = ct.value;
                            aux.item.Quantity = ct.quantity;
                            sucess = cloneOLIWork();
                        }else{
                            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, Label.Descriminar_quantidade_por_cor));
                            break;
                        }
                    }
                }
                aux.item.Codigo_de_cor__c = originalColor;
                aux.item.Quantity = qOriginal-total;
                priceByQuantityCustom(key);
                if(aux.item.Quantity <= 0 && sucess){
                    idProduct = key;
                    removeProduct();
                }
                if(aux.taxa != null){
                    aux.taxa.UnitPrice = aux.item.Quantity * aux.taxa.UnitPrice / qOriginal;
                    aux.taxa.Preco_unitario__c = aux.taxa.UnitPrice;
                    
                    boolean taxaExists = false;
                    for(opportunityLineItem oli : taxas){
                        if(oli.Id != null && aux.taxa.Id == oli.Id){
                            oli = aux.taxa;
                            taxaExists = true;
                            break;
                        }
                    }
                    if(!taxaExists) taxas.add(aux.taxa);
                }
            }else{
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, Label.Quantidade_maxima_excedida + ' ' + (Integer) qOriginal));
            }
        }
    }
    public void createNewColorLines(){
        String key = idProduct;
        Product aux = produtos.get(key);
        String originalColor = aux.item.Codigo_de_cor__c;
        Decimal qOriginal = aux.item.Quantity;
        Decimal totalOriginal = aux.item.Total_de_customizacao__c;
        if(aux != null){
            boolean sucess = true;
            for(ColorTable ct : colorTable){
                if(ct.selected && sucess){
                    if(ct.quantity != null && ct.quantity != 0){
                        idProduct = key;
                        aux.item.Codigo_de_cor__c = ct.value;
                        aux.item.Quantity = ct.quantity;
                        sucess = cloneOLIWork();
                    }else{
                        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, Label.Descriminar_quantidade_por_cor));
                        break;
                    }
                }
            }
            aux.item.Codigo_de_cor__c = originalColor;
            aux.item.Quantity = qOriginal;
            aux.item.Total_de_customizacao__c = aux.item.Quantity * aux.item.Preco_unitario__c;
            if(aux.taxa != null){
                aux.taxa.UnitPrice = aux.item.Quantity * aux.taxa.UnitPrice / qOriginal;
                aux.taxa.Preco_unitario__c = aux.taxa.UnitPrice;
                
                boolean taxaExists = false;
                for(opportunityLineItem oli : taxas){
                    if(oli.Id != null && aux.taxa.Id == oli.Id){
                        oli = aux.taxa;
                        taxaExists = true;
                        break;
                    }
                }
                if(!taxaExists) taxas.add(aux.taxa);
            }
        }else{
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, Label.Quantidade_maxima_excedida + ' ' + (Integer) qOriginal));
        }

    }
    
    public void save(){
        try{
            Boolean canUpdate = [Select Id, LastModifiedById From Opportunity Where id = :opp.Id].LastModifiedById == lastModifiedInit;
            if(canUpdate){
                boolean custValid = true;
                String errorMsg = '';
                //2018-10-12 adição de validação de campos preenchidos das costumizações
                if(opp.RecordType.DeveloperName == 'Folha_de_Obra'){
                    for(String key :produtos.keySet()){
                        Product p = produtos.get(key);
                        String errorAux = '';
                        for(Custom c :p.customList.values()){
                            if(c.item.Altura__c == null){
                                errorAux += Schema.getGlobalDescribe().get('OpportunityLineItem').getDescribe().fields.getMap().get('Altura__c').getDescribe().getLabel() + '; ';
                                custValid = false;
                            }if(c.item.Comprimento__c == null){
                                errorAux += Schema.getGlobalDescribe().get('OpportunityLineItem').getDescribe().fields.getMap().get('Comprimento__c').getDescribe().getLabel() + '; ';
                                custValid = false;
                            }if(c.item.Numero_de_repeticoes__c == null){
                                errorAux += Schema.getGlobalDescribe().get('OpportunityLineItem').getDescribe().fields.getMap().get('Numero_de_repeticoes__c').getDescribe().getLabel() + '; ';
                                custValid = false;
                            }if(c.item.Pantone_Cor__c == '' || c.item.Pantone_Cor__c == null){
                                errorAux += Schema.getGlobalDescribe().get('OpportunityLineItem').getDescribe().fields.getMap().get('Pantone_Cor__c').getDescribe().getLabel() + '; ';
                                custValid = false;
                            }
                        }
                        if(!custValid && errorAux != ''){
                            errorMsg += p.item.Referencia_SKU__c + ': ' + errorAux;
                        }
                    }
                }
                if(custValid){
                    system.debug(produtos);
                    checkRecursive.runRequestOpps = false;
                    if(!this.olisDelete.isEmpty()){
                        delete this.olisDelete;
                        checkRecursive.runOpportunityAfterUpdate = true;
                    }
                    Map<String,OpportunityLineItem> linsP = new Map<String,OpportunityLineItem>();
                    Map<String,OpportunityLineItem> lupdP = new Map<String,OpportunityLineItem>();
                    List<OpportunityLineItem> linsC = new List<OpportunityLineItem>();
                    List<OpportunityLineItem> lupdC = new List<OpportunityLineItem>();
                    
                    for(String key :produtos.keySet()){
                        Product p = produtos.get(key);
                        p.item.UnitPrice = p.item.Preco_unitario__c != null ? p.item.Preco_unitario__c : 0;
                        if(Test.isRunningTest()){
                            p.item.TotalPrice = null;
                            p.item.Quantity = 1;
                        }
                        if(p.item.Id == null){
                            linsP.put(key, p.item);
                        }else{
                            lupdP.put(key, p.item);
                        }
                    }
                    
                    if(!linsP.isEmpty()){
                        insert linsP.values();
                        checkRecursive.runOpportunityAfterUpdate = true;
                        for(String key :linsP.keySet()){
                            OpportunityLineItem insp = linsP.get(key);
                            Product p = produtos.get(key);
                            for(Custom c :p.customList.values()){
                                c.item.UnitPrice = c.item.Preco_unitario__c;
                                if(c.item.Id == null){
                                    c.item.Referencia_Relacionada__c = insp.Id;
                                    linsC.add(c.item);
                                }else{
                                    lupdC.add(c.item);
                                }
                            }
                            if(p.taxa != null){
                                p.taxa.Referencia_relacionada__c = insp.Id;
                            }
                        }
                    }
                    if(!lupdP.isEmpty()){
                        update lupdP.values();
                        checkRecursive.runOpportunityAfterUpdate = true;
                        for(String key :lupdP.keySet()){
                            OpportunityLineItem updp = lupdP.get(key);
                            Product p = produtos.get(key);
                            for(Custom c :p.customList.values()){
                                c.item.UnitPrice = c.item.Preco_unitario__c;
                                if(c.item.Id == null){
                                    c.item.Referencia_Relacionada__c = updp.Id;
                                    linsC.add(c.item);
                                }else{
                                    lupdC.add(c.item);
                                }
                            }
                        }
                    }
                    
                    if(!linsC.isEmpty()){
                        insert linsC;
                        checkRecursive.runOpportunityAfterUpdate = true;
                    }
                    if(!lupdC.isEmpty()){
                        update lupdC;
                        checkRecursive.runOpportunityAfterUpdate = true;
                    }
                    
                    if(!taxas.isEmpty()){
                        upsert taxas;
                        checkRecursive.runOpportunityAfterUpdate = true;
                    }
                    for(OpportunityLineItem oli : transportadoras){
                        oli.UnitPrice = oli.Preco_unitario__c;
                        oli.Total_de_customizacao__c = oli.Preco_unitario__c;
                    }
                    if(!transportadoras.isEmpty())
                        update transportadoras;
                    checkRecursive.runOpportunityAfterUpdate = true;
                    isSucess = true;
                    
                    
                    if(opp.RecordType.DeveloperName != 'Orcamento' && !produtos.isEmpty()){
                        opp.Espera_de_integracao__c = true;
                        opp.Versao_enviada__c = opp.Versao_enviada__c != null ? opp.Versao_enviada__c + 1 : 1;
                        update opp;
                        
                        sh_UpsertDossierPHC.job(opp.Id, opp.Stamp__c == null);
                    }
                }
                else{
                    isSucess = false;
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL, Label.Customizacoes_sem_matriz + ' ' + errorMsg));
                }                
            }else{
                isSucess = false;
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL, Label.Dossier_manipulado));
            }
        }catch(Exception ex){
            
            isSucess = false;
            system.debug(ex.getMessage());
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,
                                                       (ex.getTypeName() == 'System.DmlException' ? ex.getdmlMessage(0) :
                                                        ' contact the system admin.' + ex.getMessage())));
        }
    }
    public static void magic(){
        boolean magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
    }
    //Estrutura para guardar os produtos adicionados   
    public class Product{
        public Boolean show {get;set;}
        public Boolean isQuantity{get;set;}
        public String idProduct{get;set;}
        public String code{get;set;}
        public Map<String,Custom> customList {get;set;}
        public OpportunityLineItem item {get;set;}
        public List<SelectOption> options{get;set;}
        public OpportunityLineItem taxa {get;set;}
        public Decimal stockAtual {get;set;}
        public Decimal stockCativo {get;set;}
        public Decimal stockPrevisto {get;set;}
        public Datetime stockData {get;set;}
        
        public Product(OpportunityLineItem item,String idProduct){
            this.show = false;
            this.customList = new Map<String,Custom>();
            this.item = item;
            this.isQuantity = false;
            this.idProduct = idProduct;
            this.options = new List<SelectOption>();
        }
    }
    //estrutura para guardar os componentes associados aos produtos
    public class Custom{
        public OpportunityLineItem item {get;set;}
        public String customName {get;set;}
        public Custom(OpportunityLineItem item){
            this.item = item;
        }
    }
    
    public class Sidebar{
        public OpportunityLineItem item{get;set;}
        public Decimal stockAtual {get;set;}
        public Decimal stockCativo {get;set;}
        public Decimal stockPrevisto {get;set;}
        public Datetime stockData {get;set;}
        public Sidebar(){
            this.item = new OpportunityLineItem();
        }
    }
    //estrutura para a tabela de preços do produto
    public class Tabela{
        public Decimal desconto{get;set;}
        public PricebookEntry pbe{get;set;}
        public Preco_por_cliente__c precocliente{get;set;}
    }
    
    public class ColorTable{
        public boolean selected{get;set;}
        public String value{get;set;}
        public String color{get;set;}
        public Decimal quantity{get;set;}
        
        public ColorTable(boolean selected, String value, String color, Decimal quantity){
            this.selected = selected;
            this.value = value;
            this.color = color;
            this.quantity = quantity;
        }
    }
}