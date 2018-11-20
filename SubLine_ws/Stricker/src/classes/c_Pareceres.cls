public class c_Pareceres {
    public Pedido_de_parecer__c parecer {get;set;}
    public OrderItem line {get;set;}
    public List<UtilClaims.NewClaimLine> testList {get;set;}
    public Resposta_ao_pedido_de_parecer__mdt conf {get;set;}
    public List<BotaoDisponivel> btts {get;set;}
    public List<ContentDocument> files {get;set;}
    public ExtraInfo extraInfo {get;set;}
    public ParecerAlertaCompra alerta {get;set;}
    public boolean isAllowed {get;set;}
    public boolean isCalled {get;set;}
    
    public c_Pareceres(ApexPages.StandardController controller){
        Set<String> allowedProfile = new Set<String>();
        for(Profile_Id__mdt pimdt : [Select Id__c From Profile_Id__mdt Where DeveloperName = 'Administrador_do_sistema' Or DeveloperName = 'Departamentos']){
            allowedProfile.add(pimdt.Id__c);
            allowedProfile.add(pimdt.Id__c.left(15));
        }
        isCalled = false;
        String myId = controller.getId();
        buildParecer(myId);
        isAllowed = allowedProfile.contains(UserInfo.getProfileId()) && (parecer.Reclamacao__r.Status == 'Aberta' || parecer.Reclamacao__r.Status == 'Em análise');
        system.debug(parecer.Produto_do_pedido__r.Tipologia__c);
        system.debug(parecer.Departamento__c);
        try{
            
            conf = [Select Id, Aprovo__c,Aprovo_parcial__c,Nao_aprovo__c, Peco_foto_adicional__c,Peco_recolha__c,Quantidade_aprovada__c, Motivo__c, Upload_de_imagem__c,Causa__c
                    From Resposta_ao_pedido_de_parecer__mdt 
                    Where Tipologia_de_reclamacao__c =:parecer.Produto_do_pedido__r.Tipologia__c And Departamento__c = :parecer.Departamento__c];
        }catch(Exception ex){}

        line = [Select id, Description, Product2.Name, Reclamacao__r.CaseNumber,Reclamacao__r.Account.Name, quantidade_original__c, Referencia_Sku__c, Quantidade_reclamada__c, Product2.ProductCode , Product2.Nome_para_user__c,
                Reclamacao__r.CreatedBy.Name, Tipologia__c, Sub_Tipologia__c, Reclamacao__r.CreatedDate, Reclamacao__r.Account.Numero_de_cliente__c,Reclamacao__r.Account.BillingCountry,Referencia_base__c,UnitPrice,NDos__c,
                Reclamacao__r.Tipo_de_documento_financeiro__c, Reclamacao__r.Numero_de_documento_financeiro__c, Reclamacao__r.Data_de_emissao_do_documento_financeiro__c, CreatedBy.Name, Rua_original__c ,Tipo_dossier_abreviado__c
                
                From OrderItem Where Reclamacao__c = :parecer.Reclamacao__c and Id = :parecer.Produto_do_pedido__c Limit 1];
        
        alerta = new ParecerAlertaCompra(line);
        
        btts = new List<BotaoDisponivel>();
        if(conf != null){
            if(conf.Aprovo__c){
                BotaoDisponivel newBtt = new BotaoDisponivel('Aprovo' ,getLabelString('Aprovar'), 'Resposta_final__c', conf.Quantidade_aprovada__c, conf.Motivo__c || conf.Causa__c);
                
                btts.add(newBtt);
            }
            if(conf.Nao_aprovo__c){
                BotaoDisponivel newBtt = new BotaoDisponivel('Não aprovo' ,'_Não_Aprovo', 'Resposta_final__c', conf.Quantidade_aprovada__c, conf.Motivo__c || conf.Causa__c);
                
                btts.add(newBtt);
            }
            if(conf.Aprovo_parcial__c){
                BotaoDisponivel newBtt = new BotaoDisponivel('Aprovo parcialmente' ,'_Aprovo_parcialmente', 'Resposta_final__c', conf.Quantidade_aprovada__c, conf.Motivo__c || conf.Causa__c);
                
                btts.add(newBtt);
            }
            if(conf.Peco_foto_adicional__c){
                BotaoDisponivel newBtt = new BotaoDisponivel(true ,'_Pedir_fotos_adicionais', 'Pedido_de_fotos_adicionais__c', conf.Quantidade_aprovada__c, conf.Motivo__c || conf.Causa__c);
                
                btts.add(newBtt);
            }
            if(conf.Peco_recolha__c){
                BotaoDisponivel newBtt = new BotaoDisponivel(true ,'_Pedir_recolha', 'Pedido_de_recolha__c', conf.Quantidade_aprovada__c, conf.Motivo__c || conf.Causa__c);
                
                btts.add(newBtt);
            }
        }
    }
    
    public void buildParecer(String myId){
        if(myId != null && myId != ''){
            parecer = [Select Id, CreatedDate,Departamento__c,Produto_do_pedido__r.Tipologia__c, Reclamacao__c, Quantidade_parcial__c,Resposta_final__c,Pedido_de_fotos_adicionais__c,Pedido_de_recolha__c,Produto_do_pedido__c,
                       Motivo_de_nao_aprovacao__c,Motivo_de_aprovacao__c,Tipologia__c,Causa__c,Quantidade_a_recolher__c,Departamento_para_envio_de_recolha__c,Pedido_de_fotos_aberto__c ,Pedido_de_recolha_aberto__c
                       ,Quantidade_para_Controlo_de_Qualidade__c,Reclamacao__r.Status
                       From Pedido_de_parecer__c Where id = :myId];
        }else{
            parecer = [Select Id, CreatedDate,Departamento__c,Produto_do_pedido__r.Tipologia__c, Reclamacao__c, Quantidade_parcial__c,Resposta_final__c,Pedido_de_fotos_adicionais__c,Pedido_de_recolha__c,Produto_do_pedido__c,
                       Motivo_de_nao_aprovacao__c,Motivo_de_aprovacao__c,Tipologia__c,Causa__c,Quantidade_a_recolher__c,Departamento_para_envio_de_recolha__c,Pedido_de_fotos_aberto__c ,Pedido_de_recolha_aberto__c
                       ,Quantidade_para_Controlo_de_Qualidade__c,Reclamacao__r.Status
                       From Pedido_de_parecer__c Limit 1];
        }
    }
    
    public void callExtraInfo(){
        IntegratorClaims.servClaims.timeout_x = 120000;
        extraInfo = new ExtraInfo(IntegratorClaims.getExtraInfo(line.Id));
        
        getFicheiros();
    }
    
    public static String getLabelString(String labelName ){
        Component.Apex.OutputText output = new Component.Apex.OutputText();
        output.expressions.value = '{!$Label.' + labelName + '}';
        return String.valueOf(output.value);
    }
    
    public String updateField {get;set;}
    public Object updateValue {get;set;}
    public void escreverValor(){
        if(updateValue == 'true') updateValue = true;
        else if(updateValue == 'false') updateValue = false;
        parecer.put(updateField, updateValue);
        system.debug(parecer);
        
        update parecer;
        buildParecer(parecer.Id);
    }
    
    public String getMaquete(){

        return JSON.serialize(IntegratorClaims.getMaquete(''));
    }
    
    public HistoricoCliente getHistorico(){
        return null;
    }
    
    public String blobFile {get;set;}
    public String fileName {get;set;}
    public void newFile(){
        if(parecer.Reclamacao__c != null){
            
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
                cdl.LinkedEntityId = parecer.Id;
                cdl.ShareType = 'V';
                newShares.add(cdl);
            }
            if(!newShares.isEmpty()){
                insert newShares;
            }
            
            blobFile = null;
        }
    }
    
    public void getFicheiros(){
        Set<id> docIds = new Set<Id>();
        
        for(ContentDocumentLink link : [Select ContentDocumentid from ContentDocumentLink Where LinkedEntityId = :parecer.Id]){
            docIds.add(link.ContentDocumentId);
        }
        files = [Select Id, CreatedDate, CreatedBy.Name, Title From ContentDocument Where id In :docIds order by CreatedDate Asc];
    }
    
    public List<ContentDocument> getFicheirosLinha(){
        Set<id> docIds = new Set<Id>();
        
        for(ContentDocumentLink link : [Select ContentDocumentid from ContentDocumentLink Where LinkedEntityId = :parecer.Produto_do_pedido__c]){
            docIds.add(link.ContentDocumentId);
        }
        List<ContentDocument> temp = [Select Id, CreatedDate, CreatedBy.Name, Title From ContentDocument Where id In :docIds order by CreatedDate Asc];
        
        return temp;
    }
    
    public String getParecerPrefix(){
        return Pedido_de_Parecer__c.SObjectType.getDescribe().getKeyPrefix();
    }
    
    public String getListViewId(){
        String retStr = '';
        List<ListView> aux = [SELECT Id FROM ListView Where DeveloperName = 'X1_1_Os_meus_pareceres_pendentes'];
        if(!aux.isEmpty()) retStr = String.valueOf(aux.get(0).Id).left(15);
        return retStr;
    }
    
    public class BotaoDisponivel{
        public Object value {get;set;}
        public String label {get;set;}
        public String field {get;set;}
        public String serialized {get;set;}
        public boolean hasQttParcial {get;set;}
        public boolean hasRespOptions {get;set;}
        
        public BotaoDisponivel(Object value, String label, String field, boolean hasQttParcial, boolean hasRespOptions){
            this.value = value;
            this.label = label;
            this.field = field;
            this.hasQttParcial = hasQttParcial;
            this.hasRespOptions = hasRespOptions;
            
            serialized = Json.serialize(this);
        }
    }
}