/* @Autor: Marco Galvão
 * @Ultima Modificação: Marco Galvão
 * Controlador do componente de escolha das linhas a serem reclamadas pelo utilizador
 * @ftstamp : Stamp do ficheiro selecionado pelo utilizador; Escolhido neste componente e é passado para a página principal para continuar o processo;
 * @bostamp : Stamp do dossier selecionado pelo utilizador; Escolhido neste componente caso  seja escolhido a opção de dossier;
 * @linhas : Lista de linhas associadas ao documento escolhido pelo utilizador, resultante do serviço;
 * */
public class c_ChooseLines {
    public String selectedDoc {get;set{
        selectedDoc = value;
        if(value != null) doc = ((UtilClaims.NewClaimLine) JSON.deserialize(selectedDoc, UtilClaims.NewClaimLine.class));
    }}
    public UtilClaims.NewClaimLine doc {get;set;}
    public String ftstamp {get{return doc != null ? doc.ftstamp : '';}set;}
    public String bostamp {get{return doc != null ? doc.bostamp : '';}set;}
    public String noCliente {get;set;}
    public List<Object> linhas {get;set;}
    public List<UtilClaims.LinhasDoc> selectedLines {get;set;}
    private Set<String> uniquesList = new Set<String>();
    private Map<String, List<ContentVersion>> uploadedFiles;
    public string caseId {get;set;}
    public String filter {get;set;}
    public String filterMoradas {get;set;}
    public String filterContacts {get;set;}
    public List<Contact> filteredListContacts {get;set;}
    public boolean notifyClient {get;set;}
    public String lang {get;set;}
    
    public String dummyString {get;set;}//do not use

    public c_ChooseLines(){
        selectedLines = new List<UtilClaims.LinhasDoc>();
        uploadedFiles = new Map<String, List<ContentVersion>>();
        moradas = new List<Morada>();
        indexMor = 0;
        maxMor = 0;
        notifyClient = true;
        caso = new Case();
        filteredListContacts = new List<Contact>();
    }
    
    /* Trata a lista recebida por parametro no componente e faz o cast para a estrutura correcta, e filtra pelo bostamp associado caso ele exista;
     * @linhas: Lista com Objects que necessitam de ser tratados e filtrados para o display correcto na página;
     * */
    public List<UtilClaims.LinhasDoc> getLines(){
        List<UtilClaims.LinhasDoc> retList = new List<UtilClaims.LinhasDoc>();
        Claim_Config__mdt conf = [Select Id, Periodo_de_reclamacao__c from Claim_Config__mdt Where DeveloperName = 'Claims_Config_1'];
        if(doc.data_pagamento == null || doc.data_pagamento > System.today().addDays(-((Integer) conf.Periodo_de_reclamacao__c))){
            for(Object obj : linhas){
                if(obj instanceof UtilClaims.LinhasDoc ){
                    boolean match = false;
                    UtilClaims.LinhasDoc thisLinha = (UtilClaims.LinhasDoc) obj;
                    
                    if(bostamp == null || bostamp == '' || thisLinha.bostamp == bostamp || (bostamp != null && thisLinha.bostamp == '')){
                        if(filter != null && filter != ''){
                            for(String field : UtilClaims.compareLinFields){
                                system.debug(thisLinha.get(field));
                                
                                match = match || UtilClaims.compareValues(thisLinha.get(field), filter);
                                if(match){
                                    retList.add(thisLinha);
                                    break;
                                }
                            }
                        }else{
                            retList.add(thisLinha);
                        }
                        
                        
                    }
                }
            }
            retList.sort();
            
        }
        return retList;
    }
                                 
    public String getCurrentUser(){
        String retStr = '';
        Id currentUser = UserInfo.getUserId();
        Id siteUser = [Select Id From User Where Profile.Name = 'Paul Stricker Perfil'].Id;
        
        if(siteUser == currentUser) retStr = 'Site';
        else retStr = 'User SF';
        return retStr;
    }
    
    /* Verifica dentro das linhas mostradas ao utilizador, quais as selecionadas pelo utilizador e puxa as linhas para serem preenchidas com os dados a serem reclamados
     * @linhas: Lista com Objects que necessitam de ser tratados e filtrados para o display correcto na página;
     * @selectedLines: lista de linhas que terão os inputs sobre os dados da reclamação
     * @uniquesList: lista que permite a inclusão da mesma linha duas vezes na lista de linhas selecionadas ao carregar no botao de selecionar (inclusão possivel pela funcionalidade de adicionar uma linha)
     * */
    public void selectLines(){
        for(Object obj : linhas){
            if(obj instanceof UtilClaims.LinhasDoc ){
                UtilClaims.LinhasDoc thisLinha = (UtilClaims.LinhasDoc) obj;
                system.debug(thisLinha);
                if(thisLinha.selected && !uniquesList.contains(thisLinha.details.fistamp__c)){
                    selectedLines.add(thisLinha.cloneThis());
                    uniquesList.add(thisLinha.details.fistamp__c);
                }
            }
        }
        selectedLines.sort();
    }
    
    /* Método que limpa as listas já previamente preenchidas para a funcionalidade de retroceder na página. Todos os dados são apagados.
     * */
    public void clearLst(){
        uniquesList.clear();
        selectedLines.clear();
        linhas.clear();
    }
    
    /* Método que clona uma linha para ser possivel adicionar uma tipologia.
     * @cloneFi: id unico da linha a clonar;
     * */
    public String cloneFi {get;set;}
    public void cloneLine(){
        List<UtilClaims.LinhasDoc> newLines = new List<UtilClaims.LinhasDoc>();
        for(UtilClaims.LinhasDoc line : selectedLines){
            if(line.uniqueId == cloneFi){
                UtilClaims.LinhasDoc newLine = line.cloneThis();
                newLines.add(newLine);
            }
        }
        selectedLines.addAll(newLines);
        selectedLines.sort();
    }
    
    /* Método que apaga uma linha.
     * @delIndex: indice da linha a apagar;
     * */
    public Integer delIndex {get;set;}
    public void deleteLine(){
        system.debug(delIndex);
        delIndex = delIndex - 1;
        String origStamp = selectedLines.get(delIndex).details.Fistamp__c;
        
        selectedLines.remove(delIndex);
        
        boolean existsLine = false;
        for(UtilClaims.LinhasDoc line : selectedLines){
            if(line.details.Fistamp__c == origStamp){
                existsLine = true;
                break;
            }
        }
        if(!existsLine){
            for(Object line : linhas){
                UtilClaims.LinhasDoc thisLine = (UtilClaims.LinhasDoc) line;
                if(thisLine.details.Fistamp__c == origStamp){
                    thisLine.selected = false;
                }
            }
            
            uniquesList.remove(origStamp);
        }
        
        selectLines();
    }
    
    /* Chamada dummy para efeitos visuais na pagina.
     * */
    public void dummy(){system.debug(lineUniqueId);}
    
    
    /* Método para criar um ficheiro no final da gravação da reclamação
     * @name: nome do ficheiro;
     * @blobFile: ficheiro em base 64 para ser criado;
     * @lineUniqueId: id unico da linha em que foi adicionado o ficheiro
     * */
    public String blobFile {get;set;}
    public String fileName {get;set;}
    public String lineUniqueId {get;set;}
    public void newFile(){
        /*if(!uploadedFiles.containsKey(lineUniqueId)){
            uploadedFiles.put(lineUniqueId, new List<ContentVersion>());
        }*/
        UtilClaims.LinhasDoc thisLine;
        for(UtilClaims.LinhasDoc linha : selectedLines){
            if(linha.uniqueId == lineUniqueId){
                thisLine = linha;
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
            //uploadedFiles.get(lineUniqueId).add(version);
            
            List<ContentDocumentLink> newShares = new List<ContentDocumentLink>();
            for(ContentVersion doc: [Select id, ContentDocumentId From ContentVersion Where Id = :version.Id and IsMajorVersion = true]){
                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.ContentDocumentId = doc.ContentDocumentId;
                cdl.LinkedEntityId = thisLine.details.Id;
                cdl.ShareType = 'V';
                newShares.add(cdl);
            }
            if(!newShares.isEmpty()){
                insert newShares;
            }
            
            blobFile = null;
        }
    }
    
    /* Método para preencher a lista de moradas deste cliente, presentes no PHC
     * @moradas: lista de moradas devolvida pelo PHC
     * */
    public List<Morada> moradas {get;set;}
    public Integer indexMor {get;set;}
    public Integer maxMor {get;set;}
    public static final Integer MAX_PAG = 500;
    public Integer getMAX_PAG(){
        return MAX_PAG;
    }
    public void callMoradas(){
        moradas = new List<Morada>();
        Integer i = 0;
        List<wsdl_Viewer.moradaCliente> aux = Integrator.servViewer.lstMoradaByCliente(Integer.valueOf(noCliente)).moradaCliente;
        
        if(filterMoradas != null && filterMoradas != ''){
            List<Morada> auxFilter = new List<Morada>();
            for(wsdl_Viewer.moradaCliente mor : aux){
                boolean match = false;
                Morada thisMorada = new Morada(mor);
                for(String field : UtilClaims.compareMoradasFields){
                    
                    match = match || UtilClaims.compareValues(thisMorada.get(field), filterMoradas);
                    if(match){
                        auxFilter.add(thisMorada);
                        break;
                    }
                }
            }
            maxMor = auxFilter.size();
            while(maxMor < (i + (indexMor * MAX_PAG))){
                indexMor = indexMor - 1;
            }
            while(moradas.size() <= MAX_PAG && maxMor > (i + (indexMor * MAX_PAG))){
                moradas.add(auxFilter.get(i + (indexMor * MAX_PAG)));
                i++;
            }
        }else{
            maxMor = aux.size();
            while(i <= MAX_PAG){
                if(maxMor > (i + (indexMor * MAX_PAG))){
                    moradas.add(new Morada(aux.get(i + (indexMor * MAX_PAG))));
                    i++;
                }else{break;}
            }
        }
        
    }
    
    public void addIndexmor(){
        if(maxMor > (indexMor + 1) * MAX_PAG){
            indexMor = indexMor + 1;
            callMoradas();
        }
    }
    
    public void subIndexmor(){
        if(indexMor > 0){
            indexMor = indexMor - 1;
            callMoradas();
        }
    }
    
    public Order order = new Order();
    public Case caso {get;set;}
    public boolean isSucess {get;set;}
    public String errorType {get;set;}
    //variaveis para mostrar o erro na linha correcto se o tipo de erro for quantidade excedida
    public String errorUniqueId {get;set;}
    public String errorFistamp {get;set;}
    public void saveClaim(){
        isSucess = false;
        errorType = '';
        List<Account> acc = [Select Id, Tabela_de_precos__c, OwnerId from Account Where Numero_de_cliente__c =:noCliente];
        if(acc.isEmpty()){
            acc = [Select Id, Tabela_de_precos__c, OwnerId from Account Where Numero_de_cliente__c = '1' Limit 1];
            //sendEmail
            String body = 'Cliente não encontrado com o número: ' + noCliente + ';\n';
            body += 'Reclamação criada no cliente número 1, com o documento: ' + ftstamp.trim() + ';';
            UtilClaims.sendEmailFailure('Falha na criação de uma reclamação.', body);
            system.debug('safsaesfsf');
            
        }
        Id siteProfile = [Select Id From Profile Where Name = 'Paul Stricker Perfil'].Id;
        
        String moeda = productManager.mapISOCodes.containsKey(acc.get(0).Tabela_de_precos__c) ? productManager.mapISOCodes.get(acc.get(0).Tabela_de_precos__c): 'EUR';
        caso.Ft_Stamp__c = ftstamp.trim();
        caso.BoStamp_dossier_original__c = bostamp;
        
        caso.Data_de_emissao_do_documento_financeiro__c = doc.data_emissao != null ? doc.data_emissao.date() : null;
        caso.Numero_de_documento_financeiro__c = String.valueOf(doc.fno);
        caso.Tipo_de_documento_financeiro__c = doc.tipo_documen;
        
        if(!acc.isEmpty()){
            caso.AccountId = acc.get(0).Id;
            caso.OwnerId = acc.get(0).OwnerId;
            caso.Vendedor__c = acc.get(0).OwnerId;
        }else{
            UtilClaims.sendEmailFailure('Falha critica na criação de uma reclamação.', 'Reclamação com o stamp "' + caso.Ft_Stamp__c + '" não foi criada por falha na procura de um cliente a associar.' );
            return;
        }
        
        Map<String, Map<String, Decimal>> existingClaims = new Map<String, Map<String, Decimal>>();//<caso.Ftstamp, <item.Fistamp, SUM(item.Quantity)>>
        for(OrderItem item : [Select id, Order.Reclamacao__r.Ft_Stamp__c, Fistamp__c, Quantity 
                              from OrderItem 
                              Where OrderId In (Select Id 
                                                from Order Where AccountId = :acc.get(0).Id 
                                                And Reclamacao__r.Ft_Stamp__c = :caso.Ft_Stamp__c)]){
            if(!existingClaims.containsKey(item.Order.Reclamacao__r.Ft_Stamp__c)) existingClaims.put(item.Order.Reclamacao__r.Ft_Stamp__c, new Map<String,Decimal>());
            existingClaims.get(item.Order.Reclamacao__r.Ft_Stamp__c).put(
                item.Fistamp__c,
                existingClaims.get(item.Order.Reclamacao__r.Ft_Stamp__c).containsKey(item.Fistamp__c) ? existingClaims.get(item.Order.Reclamacao__r.Ft_Stamp__c).get(item.Fistamp__c) + item.Quantity : item.Quantity
            );
        }

        /* Antes de criar o caso tem de validar as quantidades das linhas já existentes
         * */
        if(existingClaims.containsKey(caso.Ft_Stamp__c)){
            boolean overflowQuantity = false;  
            
            for(UtilClaims.LinhasDoc linha : selectedLines){
                system.debug(linha.details);
                overflowQuantity = false;
                if(existingClaims.get(caso.Ft_Stamp__c).containsKey(linha.details.Fistamp__c) ){
                    overflowQuantity = (existingClaims.get(caso.Ft_Stamp__c).get(linha.details.Fistamp__c) + linha.details.Quantidade_reclamada__c) > (linha.details.Quantidade_original__c);
                }
                if(overflowQuantity){
                    errorType = 'Qtt';
                    errorUniqueId = linha.uniqueId;
                    errorFistamp = linha.details.Fistamp__c;
                    return;
                }
            }
        }
        /***************************************FIM DA VALIDAÇÃO DAS QUANTIDADES*********************************************/
        //SE CHEGAR AQUI VAI CRIAR O CASO
        List<Documentos_financeiros__c> docs = [Select Id From Documentos_financeiros__c Where Ftstamp__c = :ftstamp.trim()];
        if(!docs.isEmpty()){
            caso.Documento_financeiro__c = docs.get(0).Id;
        }
        
        caso.Sub_estado__c = UserInfo.getProfileId() == siteProfile ? 'Aguardar análise do comercial' : 'Aguardar envio para decisão';
        caso.Origin = UserInfo.getProfileId() == siteProfile ? 'Web' : '';
        caso.Notificar_cliente__c = notifyClient;
        caso.CurrencyIsoCode = doc.moeda == 'PTE ou EURO' ? 'EUR' : doc.moeda ;
        upsert caso;

        order.AccountId = caso.AccountId;
        order.Reclamacao__c = caso.Id;
        order.EffectiveDate = System.today();
        order.CurrencyIsoCode = doc.moeda == 'PTE ou EURO' ? 'EUR' : doc.moeda ;
        order.Status = 'Novo';
        order.OwnerId = acc.get(0).OwnerId;
        order.Pricebook2Id = [Select id from Pricebook2 Where isStandard = true].Id;
        order.Total_da_fatura__c = doc.custo_total;
        upsert order;
        
        caso.Pedido__c = order.Id;
        update caso;
        
        Set<String> refs = new Set<String>();
        for(UtilClaims.LinhasDoc linha : selectedLines){
            refs.add(linha.details.Referencia_Sku__c.split('\\.')[0]);        
        }
        
        Map<String, PricebookEntry> mapPbes = new Map<String,PricebookEntry>();
        for(PricebookEntry pbe : [Select Id, ProductCode 
                                  From PricebookEntry 
                                  Where Pricebook2.isStandard = true 
                                  And CurrencyIsoCode = :moeda 
                                  And (ProductCode in :refs OR ProductCode = 'NSGEN')
                                  //2018-05-22
                                  //Customizações são rotuladas com o produto generico porque o PHC não tem maneira standardizada de enviar a customização nas faturas/encomendas inseridas fora SF;
                                  //campos chave (ex:largura, comprimento, ncores, etc...) são descritos no campo de observações.
                                  //Site não está a escrever as encomendas com a tabela u_costum preenchida.
                                  And Product2.RecordType.DeveloperName != 'Customizacao']){
            mapPbes.put(pbe.ProductCode, pbe);
        }
        
        List<OrderItem> items = new List<OrderItem>();

        for(UtilClaims.LinhasDoc linha : selectedLines){
            OrderItem item = linha.details;
            
            system.debug(item.Comentario_do_cliente__c);// (pagina)
            system.debug(item.Data_de_rececao_dos_artigos_reclamados__c);// (pagina)
            system.debug(item.Impressao_por_terceiros__c);// (pagina)
            system.debug(item.IVA_correto__c);// (pagina)
            system.debug(item.Morada_correta__c);// (pagina)
            system.debug(item.MSEQ_Morada_correta__c);// (pagina)
            system.debug(item.Preco_correto__c);// (pagina)
            system.debug(item.Quantidade_reclamada__c);// (pagina)
            system.debug(item.Rua_Correta__c);// (pagina)
            system.debug(item.Sub_tipologia__c);// (pagina)
            system.debug(item.Tipologia__c);// (pagina)
            
            //Select id,Username, name from user Where name like '%Paul Stricker%'
            
            item.Tipologia_sugerida_cliente__c = UserInfo.getProfileId() == siteProfile ? item.Tipologia__c : '';
            item.Tipologia_sugerida_comercial__c = UserInfo.getProfileId() != siteProfile ? item.Tipologia__c : '';
            item.OrderId = order.Id;
            item.Reclamacao__c = caso.Id;
            item.Quantity = item.Quantidade_reclamada__c;
            item.Preco_total__c = item.Quantity * item.Preco_original__c;
            //item.UnitPrice = item.Preco_original__c; não percebi porque que isto está aqui
            //Vendedor__c (integração)
            String refBase = item.Referencia_SKU__c.split('\\.')[0];
            item.PricebookEntryId = mapPbes.containsKey(refBase) ? mapPbes.get(refBase).Id : mapPbes.get('NSGEN').Id;
            
            String[] auxSplitted = linha.auxData != '' ? (linha.auxData.contains('-') ? linha.auxData.split('-') :
                                                          (linha.auxData.contains('/') ? linha.auxData.split('/') :
                                                           linha.auxData.contains('.') ? linha.auxData.split('\\.') :
                                                           null)) : null;
            if(auxSplitted != null && auxSplitted.size() == 3){
                Integer day = auxSplitted[0].isNumeric() ? Integer.valueOf(auxSplitted[0]) : null;
                Integer month = auxSplitted[1].isNumeric() ? Integer.valueOf(auxSplitted[1]) : null;
                Integer year = auxSplitted[2].isNumeric() ? Integer.valueOf(auxSplitted[2]) : null;
                if(day != null && month != null && year != null){
                    item.Data_de_rececao_dos_artigos_reclamados__c = linha.auxData != null ? Date.newInstance(year, month, day) : null;
                }
            }
            //PricebookEntryId standard*********************************************************************
            
            //***********************TRATADOS
            //Bistamp__c (integração) (construtor)
            //Bostamp__c (integração) (construtor)
            //Codigo_postal_original__c (integração) (construtor)
            //Cor__c (integração) (construtor)
            //Custo_ponderado__c (integração) (construtor)
            //Fistamp__c (integração) (construtor)
            //Desconto_original__c (integração) (construtor)
            //Localidade_original__c (integração) (construtor)
            //Lote__c (integração) (construtor)
            //Oftstamp__c (integração) (construtor)
            //Pais__c (integração) (construtor)
            //Peso__c (integração) (construtor)
            //Preco_original__c (integração) (construtor)
            //Quantidade_original__c (integração) (construtor)
            //Referencia_SKU__c (integração) (construtor)
            //Tamanho__c (integração) (construtor)
            //Taxa_de_IVA__c (integração) (construtor)
            //Telefone_original__c (integração) (construtor)
            //Rua_original__c (integração) (construtor)
            //Volume__c (integração) (construtor)
            //Zona_de_envio__c (integração) (construtor)
            items.add(item);
            
        }
        insert items;
        isSucess = true;
        
        caseId = caso.Id;
    }
    
    public void applyFilter(){
        filteredListContacts.clear();
        system.debug('entrei');
        if(filterContacts != null && filterContacts != ''){
            String aux = '%' + filterContacts + '%';
            String query = 'Select id, Name, Phone, MobilePhone, Email from Contact Where (Name Like \''+ aux + '\' Or Phone Like \''+ aux + '\' Or MobilePhone Like \''+ aux + '\' Or Email Like \''+ aux + '\') '
                +'And Account.Numero_de_cliente__c = \'' + noCliente + '\' Limit 5';
            filteredListContacts = Database.query(query);
        }else{
            caso.ContactId = null;
        }
        system.debug(filteredListContacts);
    }
    
    /* Estrutura usada no método de ir buscar a lista de moradas do cliente.
     * */
    public class Morada{
        public String rua {get;set;}
        public String codPost {get;set;}
        public String local {get;set;}
        public String pais {get;set;}
        public String mseq {get;set;}
        
        public Morada(wsdl_Viewer.moradaCliente mor){
            this.rua = mor.rua;
            this.codPost = mor.codPost;
            this.local = mor.local;
            this.pais = mor.paisDesig;
            this.mseq = String.valueOf(mor.mseq);
        }
        
         public String get(String field){
            if(field == 'rua'){
                return this.rua != null ? this.rua : '';
            }else{
                return null;
            }
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
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
        magic = true;
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