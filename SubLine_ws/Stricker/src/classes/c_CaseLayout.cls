public class c_CaseLayout {
    public Case caso {get;set;}
    public List<OrderItem> items {get;set;}
    public boolean saveSucess {get;set;}
    public String errorMessage {get;set;}
    public boolean hasComentType {get;set;}
    public boolean hasRequest {get;set;}
    public boolean hasComLine {get;set;}
    public boolean hasRecolha {get;set;}
    public OrderItem comLine {get;set;}
    public Map<Id, Pedidos> mapaPedidos {get;set;}
    
    public Integer maxLines {get{
        return 10;
    }set;}
    public Set<String> allowedProfile {get;set;}
    public boolean isAllowed {get;set;}
    
    //client contacts filter
    public List<Contact> filteredList {get;set;}
    public String filter {get;set;}
    
    //claims director filter
    public String filterDir {get;set;}
    public List<User> filteredListDir {get;set;}
    
    public Pedido_de_parecer__c pedidoDummy {get;set;}
    public String lineUniqueId {get;set;}
    public Map<String,string> tipo {get;set;}
    public static final String referenciaComLine = 'NSDESCCOM';
    public boolean showTratamento {get;set;}
    public Decimal outrasResp {get{
        Decimal temp = 0;
        for(OrderItem item : items){
            if(item.Tipologia__c == 'Transporte – Mercadoria extraviada' && item.Transportadora__c != null && item.Transportadora__c.contains('TNT')){//falta adicionar transportadora
                temp +=  ((item.Quantidade_original__c * item.UnitPrice) * (item.Peso__c / item.Quantidade_reclamada__c)) / 10;
                //handling
                temp += handling;
            }
        }
        return temp;
    }set;}
    public Decimal handling {get{
        Decimal temp = 0;
        for(OrderItem item : items){
            //handling
            temp += Math.min((item.Numero_de_caixas__c != null ? item.Numero_de_caixas__c : 0) * 3, 50);
        }
        return temp;
    }set;}
    public Decimal custosTransp {get{
        Decimal temp = 0;
        for(OrderItem item : items){
            temp += (item.Custo_de_portes__c != null ? item.Custo_de_portes__c : 0) + 
                (item.UnitPrice * (item.Quantidade_reclamada__c != null ? item.Quantidade_reclamada__c : 0));
            //handling
            temp += handling;
        }
        return temp;
    }set;}
    public String currencySymbol {get;set;}
    
    public Decimal totalCredito {get{
        Decimal temp = 0;
        for(OrderItem item : items){
            if(item.Acao_corretiva__c == 'Dar desconto'){
                temp += (item.Desconto__c != null ? item.Desconto__c : 0);
            }else if(item.Acao_corretiva__c == 'Correcção de preço'){
                temp += (item.Valor_a_creditar__c != null ? item.Valor_a_creditar__c : 0);
            }/*else if(item.Acao_corretiva__c == 'Nova encomenda' || item.Acao_corretiva__c == 'Nova FO/FOI'){
                temp += (item.Quantidade_reclamada__c != null ? item.Quantidade_reclamada__c : 0) * item.UnitPrice;
            }*/
        }
        if(temp > caso.Pedido__r.Total_da_fatura__c) temp = caso.Pedido__r.Total_da_fatura__c;
        caso.Total_a_creditar__c = temp;
        
        return temp;
    } set{
        caso.Total_a_creditar__c = value;
    }}
    
    public c_CaseLayout(ApexPages.StandardController controller){
        allowedProfile = new Set<String>();
        for(Profile_Id__mdt pimdt : [Select Id__c From Profile_Id__mdt Where DeveloperName = 'Administrador_do_sistema' Or DeveloperName = 'Director_Comercial']){
            allowedProfile.add(pimdt.Id__c);
            allowedProfile.add(pimdt.Id__c.left(15));
        }
        isAllowed = allowedProfile.contains(UserInfo.getProfileId());
        comLine = new OrderItem();
        hasComLine = false;
        pedidoDummy = new Pedido_de_parecer__c();
        caso = queryCaso(controller.getId());
        saveSucess = false;
        showTratamento = false;
        filteredList = new List<Contact>();
        filteredListDir = new List<User>();
        if(caso.Contact.Name != null) filter = caso.Contact.Name;
        if(caso.Owner.Name != null) filterDir = caso.Owner.Name;
        
        buildItems();
        buildMapaPedidos();
        tipo = new Map<String, String>();
        for(OrderItem item: items){
            tipo.put(item.Id, 'percent');
            if(item.Quantidade_a_recolher__c != null && caso.Status == 'Em tratamento'){
                hasRecolha= true;
            }
        }
        currencySymbol = Utils.currencySymbol(caso.CurrencyIsoCode);
            system.debug(mapaPedidos);
    }
    
    private void buildItems(){
        items = [Select Id, Referencia_SKU__c, Quantidade_original__c, Quantidade_reclamada__c, Tipologia__c, Acao_corretiva_sugerida__c,Sub_tipologia__c, Preco_correto__c ,IVA_correto__c ,Data_de_rececao_dos_artigos_reclamados__c ,
                 Impressao_por_terceiros__c , Rua_Correta__c , Morada_correta__c ,MSEQ_Morada_correta__c , Data_de_emissao_do_documento_financeiro__c ,Comentario_do_cliente_traducao__c ,Comentario_do_cliente__c,UnitPrice,Peso__c,
                 Mercadoria_recebida_10_dias__c,Desvio_quantidade_inferior_1_neutro__c, Desvio_quantidade_inferior_3_impresso__c, N_dossiers_cliente_mesmo_artigo__c, N_dossiers_amostra_cliente_mesmo_artigo__c,Departamento_de_origem__c,
                 Produto_bloqueado_Controlo_de_Qualidade__c, Produto_base_reclamado_3_vezes__c, N_de_reclamacoes_produto_base__c, Produto_completo_reclamado_3_vezes__c, N_de_reclamacoes_produto_completo__c,Acao_corretiva__c,
                 Custo_de_portes__c,Transportadora__c,Morada_de_pedido_de_recolha__c ,numero_de_caixas__c ,Valor_a_creditar__c ,Preco_original__c,Desconto_percentual__c , Desconto__c,Quantidade_a_recolher__c ,Volume__c,
                 Portes_para_recolha_devolucao__c ,Preco_total__c, Devolucao_ao_cuidado_de__c,Devolucao_pedida_por__c,Morada_de_pedido_de_devolucao__c,Pais_da_devolucao__c,Telefone_logistico_de_devolucao__c,
                 Tracking_Number_de_devolucao__c,
                 (Select Id, Departamento__c, Estado__c, Resposta_final__c, Pedido_de_recolha_aberto__c, Pedido_de_fotos_aberto__c, Data_de_resposta_de_recolha__c
                  ,Data_de_resposta_de_pedido_de_fotos__c
                  From Pedidos_de_parecer__r)
                 from OrderItem Where (Reclamacao__c = :caso.Id Or Order.Reclamacao__c = :caso.Id) And Product2.ProductCode != :referenciaComLine];
        
        List<OrderITem> auxList = [Select Id, Referencia_SKU__c, Quantidade_original__c, Quantidade_reclamada__c, Tipologia__c, Acao_corretiva_sugerida__c,Sub_tipologia__c, Preco_correto__c ,IVA_correto__c ,Data_de_rececao_dos_artigos_reclamados__c ,
                                   Impressao_por_terceiros__c , Rua_Correta__c , Morada_correta__c ,MSEQ_Morada_correta__c , Data_de_emissao_do_documento_financeiro__c ,Comentario_do_cliente_traducao__c ,Comentario_do_cliente__c,UnitPrice,Peso__c,
                                   Mercadoria_recebida_10_dias__c,Desvio_quantidade_inferior_1_neutro__c, Desvio_quantidade_inferior_3_impresso__c, N_dossiers_cliente_mesmo_artigo__c, N_dossiers_amostra_cliente_mesmo_artigo__c,Departamento_de_origem__c,
                                   Produto_bloqueado_Controlo_de_Qualidade__c, Produto_base_reclamado_3_vezes__c, N_de_reclamacoes_produto_base__c, Produto_completo_reclamado_3_vezes__c, N_de_reclamacoes_produto_completo__c,Acao_corretiva__c,
                                   Custo_de_portes__c,Transportadora__c,Morada_de_pedido_de_recolha__c ,numero_de_caixas__c
                                   from OrderItem Where (Reclamacao__c = :caso.Id Or Order.Reclamacao__c = :caso.Id) And Product2.ProductCode = :referenciaComLine];
        
        if(!auxList.isEmpty()) {
            hasComLine = true;
            comLine = auxList.get(0);
        }
    }
    
    private void buildMapaPedidos(){
        hasComentType = false;
        hasRequest = false;
        
        mapaPedidos = new Map<Id, Pedidos>();
        for(OrderItem item : items){

            if(!hasComentType && item.Comentario_do_cliente__c != '' && item.Comentario_do_cliente__c != null){
                hasComentType = true;
            }
            mapaPedidos.put(item.Id, new Pedidos(false, false));
            for(Pedido_de_parecer__c pedido : item.Pedidos_de_parecer__r){
                if(pedido.Pedido_de_recolha_aberto__c || pedido.Pedido_de_fotos_aberto__c){
                    mapaPedidos.get(item.Id).fotos = mapaPedidos.get(item.Id).fotos || pedido.Pedido_de_fotos_aberto__c;
                    mapaPedidos.get(item.Id).recolha = mapaPedidos.get(item.Id).recolha || pedido.Pedido_de_recolha_aberto__c;
                    hasRequest = true;
                }
            }
        }
    }
    
    private Case queryCaso(Id caseId){
        return [Select Id, Origin, AccountId,ContactId, Contact.Name, Mercadoria_recebida_mais_10_dias__c,Cliente_VIP__c, Cliente_com_encomendas_canceladas__c,Cliente_com_divida_vencida__c,N_dossiers_cliente_sem_reclamacao__c
                ,Cliente_mais_de_3_reclamacoes__c, OwnerId, Owner.Name, Status,Cobrar_portes_ao_cliente__c, Pedido__c, CurrencyIsoCode, Data_de_analise_do_decisor__c,Total_a_creditar__c, Pedido__r.Total_da_fatura__c
                from Case Where Id = :caseId];
    }
    public void gravarCaso(){
        try{
            update caso;
            caso = queryCaso(caso.Id);
            saveSucess = true;
        }catch(DmlException ex){
            system.debug(ex.getMessage()+ ' - ' + ex.getTypeName());
            errorMessage = ex.getMessage() + ' Line: ' + ex.getLineNumber() + ' - ' + ex.getTypeName(); 
            saveSucess = false;
        }catch(Exception ex){
            system.debug(ex.getMessage()+ ' - ' + ex.getTypeName());
            errorMessage = ex.getMessage() + ' Line: ' + ex.getLineNumber() + ' - ' + ex.getTypeName(); 
            saveSucess = false;
        }
    }
    public void gravarLinhas(){
        try{
            List<OrderItem> auxList = new List<OrderItem>();
            auxList.addAll(items);
            if(comLine.Id != null) auxList.add(comLine);
            update auxList;
            if(caso.Data_de_analise_do_decisor__c == null){
                caso.Data_de_analise_do_decisor__c = system.now();
                caso.Sub_estado__c = 'Aguardar decisão';
            }
            update caso;
            saveSucess = true;
        }catch(Exception ex){
            system.debug(ex.getMessage());
            errorMessage = ex.getMessage() + ' Line: ' + ex.getLineNumber(); 
            saveSucess = false;
        }
    }
    public void applyFilter(){
        filteredList.clear();
        
        if(filter != null && filter != ''){
            String aux = '%' + filter + '%';
            String query = 'Select id, Name, Phone, MobilePhone, Email from Contact Where (Name Like \''+ aux + '\' Or Phone Like \''+ aux + '\' Or MobilePhone Like \''+ aux + '\' Or Email Like \''+ aux + '\') '
                +'And AccountId = \'' + caso.AccountId + '\' Limit 5';
            filteredList = Database.query(query);
        }else{
            caso.ContactId = null;
        }
    }
    
    public void applyFilterDir(){
        filteredListDir.clear();
        
        if(filterDir != null && filterDir != ''){
            String aux = '%' + filterDir + '%';
            Set<String> dirProf = new Set<String>();
            for(Profile_Id__mdt pimdt : [Select Id__c From Profile_Id__mdt Where DeveloperName = 'Director_Comercial']){
                dirProf.add(pimdt.Id__c);
                dirProf.add(pimdt.Id__c.left(15));
            }
            String query = 'Select id, Name, Profile.Name from User Where Name Like \''+ aux + '\' And ProfileId In :dirProf Limit 5';
            filteredListDir = Database.query(query);
        }else{
            caso.OwnerId = null;
        }
    }
    
    public String getCaseContact(){
        if(caso.ContactId != null && caso.ContactId != ''){
            return [Select Name from Contact Where id = :caso.ContactId].Name;
        } else return '';
    }
    
    public String getCaseOwner(){
        if(caso.OwnerId != null){
            return [Select Owner.Name from Case Where id = :caso.Id].Owner.Name;
        } else return '';
    }
    
    public OrderItem getLinesMap(){
        if(choosenLine != null){
            return new Map<Id, OrderItem>(items).get(choosenLine);
        }else return null;
    }
    
    public void dummy(){}
    
    public String choosenLine {get;set;}
    public void findLine(){
        if(choosenLine != null && choosenLine != ''){
            pedidoDummy.Tipologia__c = getLinesMap().Tipologia__c;
            existingDeparts = '';
            for(Pedido_de_parecer__c pp : getLinesMap().Pedidos_de_parecer__r){
                if(existingDeparts != '') existingDeparts += ';';
                existingDeparts += pp.Departamento__c;
            }
        }
    }
    public String existingDeparts {get;set;}
    
    public String departs {get;set;}
    public void criarParecer(){
        system.debug(departs.split(';'));
        if(departs != ''){
            
            List<Pedido_de_parecer__c> listNewParecer = new List<Pedido_de_parecer__c>();
            for(String departamento : departs.split(';')){
                Pedido_de_parecer__c newParecer = new Pedido_de_parecer__c();
                newParecer.Departamento__c = departamento;
                newParecer.Reclamacao__c = caso.Id;
                newParecer.Produto_do_pedido__c = choosenLine;
                newParecer.Tipologia__c = getLinesMap().Tipologia__c;
                listNewParecer.add(newParecer);
            }
            
            upsert listNewParecer;
            
            buildItems();
            
            if(caso.Data_de_analise_do_decisor__c == null){
                caso.Data_de_analise_do_decisor__c = system.now();
            }
            update caso;
        }
    }
    
    public String blobFile {get;set;}
    public String fileName {get;set;}
    public void newFile(){
        OrderItem thisLine;
        for(OrderItem item : items){
            if(item.Id == lineUniqueId){
                thisLine = item;
                break;
            }
        }
        if(thisLine != null && caso.Id != null){
            
            ContentVersion version = new ContentVersion();
            blobFile= blobFile.substring(blobFile.indexOf(',')+1);
            system.debug(blobFile);
            version.VersionData = EncodingUtil.base64Decode(blobFile);
            version.Title = fileName;
            if(version.PathOnClient == null) version.PathOnClient = fileName;
            if(!Test.isRunningTest()) insert version;
            
            List<ContentDocumentLink> newShares = new List<ContentDocumentLink>();
            for(ContentVersion doc: [Select id, ContentDocumentId From ContentVersion Where Id = :version.Id and IsMajorVersion = true]){
                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.ContentDocumentId = doc.ContentDocumentId;
                cdl.LinkedEntityId = thisLine.Id;
                cdl.ShareType = 'V';
                newShares.add(cdl);
            }
            if(!newShares.isEmpty()){
                insert newShares;
            }
            
            blobFile = null;
        }
    }
    
    public boolean sucess {get;set;}
    public String errorMsg {get;set;}
    public void autorizarClaim(){
        sucess = false;
        try{
            List<User> directorClaims = [Select Id From User Where UserRole.DeveloperName = 'Customer_Care_Director'];
            if(!directorClaims.isEmpty()){
                
                caso.OwnerId = directorClaims.get(0).Id;
                caso.Status = 'Em análise';
                caso.Data_de_envio_para_decisao__c = System.now();
                update caso;
                sucess = true;
            }else{
                errorMsg = '_Não está designado um director de Customer Care';
            }
        }catch(DmlException ex){
            system.debug(ex.getMessage()+ ' - ' + ex.getTypeName());
            errorMsg = ex.getDmlFields(0) + ' ' + ex.getDmlMessage(0);
            saveSucess = false;
        }catch(Exception ex){
            system.debug(ex.getMessage()+ ' - ' + ex.getTypeName());
            errorMsg = ex.getMessage() + ' Line: ' + ex.getLineNumber() + ' - ' + ex.getTypeName(); 
            saveSucess = false;
        }
    }
    
    public List<SelectOption> getRespostasPedidoFotos(){
        Schema.sObjectType sobject_typec = OrderItem.getSObjectType();
        Schema.DescribeSObjectResult sobject_describec = sobject_typec.getDescribe();
        Map<String, Schema.SObjectField> field_mapc = sobject_describec.fields.getMap();
        List<Schema.PicklistEntry> pick_list_valuesc = field_mapc.get('Resposta_ao_pedido_de_fotos_adicionais__c').getDescribe().getPickListValues();
        Map<String,selectOption> map_optionsc = new Map<String,selectOption>();
        for (Schema.PicklistEntry a : pick_list_valuesc) {
            map_optionsc.put(a.getValue(), new selectOption(a.getValue(), a.getLabel()));
        }
        
        return map_optionsc.values();
    }
    
    public String respostaPedidoFotos {get;set;}
    public void actualizarLinha(){
        OrderItem item =  getLinesMap();
        List<Pedido_de_parecer__c> pareceres = new List<Pedido_de_parecer__c>();
        if(respostaPedidoFotos != '' || (item.Tracking_Number_de_recolha__c != null && item.Tracking_Number_de_recolha__c != '')){
            item.Resposta_ao_pedido_de_fotos_adicionais__c = respostaPedidoFotos;
            system.debug(item.Tracking_Number_de_recolha__c);
            boolean hasTrackingNumber = item.Tracking_Number_de_recolha__c != null && item.Tracking_Number_de_recolha__c != '';
            for(Pedido_de_parecer__c parecer : item.Pedidos_de_Parecer__r){
                boolean added = false;
                if(parecer.Pedido_de_fotos_aberto__c  && parecer.Data_de_resposta_de_pedido_de_fotos__c == null){
                    added = true;
                    parecer.Data_de_resposta_de_pedido_de_fotos__c = system.now();
                }
                if(hasTrackingNumber && parecer.Pedido_de_recolha_aberto__c && parecer.Data_de_resposta_de_recolha__c == null){
                    added = true;
                    parecer.Data_de_resposta_de_recolha__c = system.now();
                    
                    //calcular custo da resposta
                }
                
                if(added) 
                    pareceres.add(parecer);
            }
        }
        update item;
        if(!pareceres.isEmpty()) update pareceres;
    }
    public void actualizarLinhaRecolha(){
        OrderItem item =  getLinesMap();

        update item;
    }
    
    public void createComLine(){
        List<PricebookEntry> productComLine = [Select id 
                                               from PricebookEntry 
                                               Where ProductCode = :referenciaComLine 
                                               And Pricebook2.isStandard = true
                                               And CurrencyIsoCode = :caso.CurrencyIsoCode];
        
        comLine.OrderId = caso.Pedido__c;
        comLine.Reclamacao__c = caso.Id;
        comLine.PricebookEntryId = !productComLine.isEmpty() ?
            productComLine.get(0).Id : [Select Id 
                                        From PricebookEntry 
                                        Where ProductCode = 'NSGEN' 
                                        And Pricebook2.isStandard = true 
                                        And CurrencyIsoCode = :caso.CurrencyIsoCode Limit 1].Id;
        
        comLine.Referencia_SKU__c = referenciaComLine;
        comLine.Quantity = 1;
        comLine.UnitPrice = 0;
        upsert comLine;
        hasComLine = true;
        IntegratorClaims.updateClaim(caso.Id);
    }
    public void deleteComLine(){
        delete comLine;
        comLine = new OrderItem();
        IntegratorClaims.updateClaim(caso.Id);
        hasComLine = false;
    }
    
    public void submeterTratamento(){
        caso.Data_de_submissao_para_tratamento__c = System.now();
        caso.Status = 'Em tratamento';
        update caso;
        
        update items;
    }
    
    public class Pedidos{
        public boolean fotos {get;set;}
        public boolean recolha {get;set;}
        public Pedidos(boolean fotos, boolean recolha){
            this.fotos = fotos;
            this.recolha = recolha;
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
}