global class w_SalesforcePSWebService {
    webservice static boolean dossierImpresso(String stamp, boolean impresso){
        Opportunity opp = new Opportunity();
        opp.Stamp__c = stamp;
        opp.Impresso__c = impresso;
        try{
            Database.upsert(opp, Opportunity.Stamp__c, false);
            return true;
        }catch(Exception ex){return false;}
    }
    
    webservice static boolean dossierImpressoList(List<String> stamps, boolean impresso){
        List<Opportunity> opps = new List<Opportunity>();
        system.debug(stamps);
        for(String stamp :stamps){
            if(stamp != null && stamp != 'null' && stamp != ''){
                Opportunity opp = new Opportunity();
                opp.Stamp__c = stamp;
                opp.Impresso__c = impresso;
                opps.add(opp);
            }
        }
        try{
            Database.upsert(opps, Opportunity.Stamp__c, false);
            return true;
        }catch(Exception ex){return false;}
    }
    
    webservice static ClientUpsertResult clientUpsert(Cliente cliente){
        //vendedores
        Map<String, User> usersMap = new Map<String, User>();
        
        for(User user : [Select id, Codigo_de_utilizador__c, IsActive from User]){
            usersMap.put(user.Codigo_de_utilizador__c, user);
        }
        system.debug(cliente);
        cliente.moeda = cliente.moeda == 'PTE ou EURO' ? 'EUR' : cliente.moeda;
        
        Account acc = new Account();
        if(cliente.no != null)
            acc.Numero_de_cliente__c = cliente.no;
        if(cliente.bloqueado != null)
            acc.Bloqueado__c = cliente.bloqueado;
        if(cliente.inativo != null)
            acc.Inativo__c = cliente.inativo;
        if(cliente.tipo != null)
            acc.Type = cliente.tipo;
        if(cliente.enc_canceladas != null){
            acc.Encomendas_canceladas__c = cliente.enc_canceladas;
            //2018-10-22
           if(!cliente.enc_canceladas) acc.Notificacao_novo_cliente__c = true;
        }
        if(cliente.contencioso != null)
            acc.Contencioso__c = cliente.contencioso;
        //if(cliente.vendedor != null)
        //if(usersMap.containsKey(cliente.vendedor)) acc.Vendedor__c = usersMap.get(cliente.vendedor).Id;
        if(cliente.tab_precos != null)
            acc.Tabela_de_precos__c = cliente.tab_precos;
        if(cliente.obj_fat != null)
            acc.Objectivo_de_faturacao_anual__c = CurrencyConverter.convert(cliente.obj_fat, 'EUR', cliente.moeda);
        if(cliente.div_nao_titulada_maturidade != null)
            acc.Divida_nao_titulada_maturidade__c = cliente.div_nao_titulada_maturidade;
        if(cliente.div_nao_titulada_saldo != null)
            acc.Divida_nao_titulada_saldo__c = CurrencyConverter.convert(cliente.div_nao_titulada_saldo, 'EUR', cliente.moeda);
        if(cliente.div_titulada_maturidade != null)
            acc.Divida_titulada_maturidade__c = cliente.div_titulada_maturidade;
        if(cliente.div_titulada_saldo != null)
            acc.Divida_titulada_saldo__c = CurrencyConverter.convert(cliente.div_titulada_saldo, 'EUR', cliente.moeda);
        if(cliente.lim_cred_comercial != null)
            acc.Limite_de_credito_comercial__c = cliente.lim_cred_comercial;
        if(cliente.lim_oper_divida != null)
            acc.Limite_operacional_de_divida__c = cliente.lim_oper_divida;
        if(cliente.plafond_comercial != null)
            acc.Plafond_comercial__c = CurrencyConverter.convert(cliente.plafond_comercial, 'EUR', cliente.moeda);
        if(cliente.plafond_operacional != null)
            acc.Plafond_operacional__c = CurrencyConverter.convert(cliente.plafond_operacional, 'EUR', cliente.moeda);
        if(cliente.tipo_fat != null)
            acc.Tipologia_de_facturacao__c = cliente.tipo_fat;
        if(cliente.tax_iva != null)
            acc.Taxa_de_IVA__c = cliente.tax_iva;
        if(cliente.merc_cust != null)
            acc.Mercado_de_customizacoes__c = cliente.merc_cust != 'null' ? cliente.merc_cust : null;
        if(cliente.merc_cust != null)
            if(acc.Mercado_de_customizacoes__c != '') acc.Tabela_de_customizacoes__c = true;
        if(cliente.nomeEmpresa != null)
            acc.Name = cliente.nomeEmpresa;//EncodingUtil.urlDecode(cliente.nomeEmpresa, 'UTF-8'); Removido por adicição de encoding UTF-8 do lado do evocante
        if(cliente.tabIVA != null)
            acc.Codigo_de_IVA__c = cliente.tabIVA;
        if(cliente.dir_comercial != null)
            if(usersMap.containsKey(cliente.dir_comercial) && usersMap.get(cliente.dir_comercial).isActive) acc.Diretor_comerial__c = usersMap.get(cliente.dir_comercial).Id;
        if(cliente.preNIF != null)
            acc.Prefixo_de_contribuinte__c = cliente.preNIF;
        if(cliente.nif != null)
            acc.Numero_de_contribuinte__c = cliente.nif;
        if(cliente.nomeab != null)
            acc.Nome_abreviado__c = cliente.nomeab;
        if(cliente.divida_vencida != null)
            acc.Divida_vencida__c = CurrencyConverter.convert(cliente.divida_vencida, 'EUR', cliente.moeda);
        if(cliente.escalao_hidea != null)
            acc.Escalao_Hidea__c = cliente.escalao_hidea;
        
        //Novos campos
        if(cliente.pais != null)
            acc.BillingCountry = cliente.pais;//pais do cliente
        if(cliente.zona != null)
            acc.Zona__c = cliente.zona;//zona do cliente
        if(cliente.local != null)
            acc.BillingCity = cliente.local;//localidade do cliente
        if(cliente.morada != null)
            acc.BillingStreet = cliente.morada;//morada do cliente
        if(cliente.cod_post != null)
            acc.BillingPostalCode = cliente.cod_post;//codigo postal do cliente
        if(cliente.vend_nome != null)
            if(usersMap.containsKey(cliente.vend_nome) && usersMap.get(cliente.vend_nome).isActive) {
                acc.OwnerId = usersMap.get(cliente.vend_nome).Id;//nome vendedor
                acc.Owner_PHC__C = null;
            } else {
                acc.Owner_PHC__C = cliente.vend_nome;
            }
        if(cliente.assistent != null)
            if(usersMap.containsKey(cliente.assistent) && usersMap.get(cliente.assistent).isActive)  acc.Assistente_comercial__c = usersMap.get(cliente.assistent).Id;//assistente comercial
        if(cliente.doc_dest != null)
            acc.Documento_de_destino__c = cliente.doc_dest;//documento destino
        if(cliente.idioma_fat != null)
            acc.Idioma_para_faturacao__c = cliente.idioma_fat;//idioma de faturação
        if(cliente.website != null)
            acc.Website = cliente.website;//website
        if(cliente.phone != null)
            acc.Phone = cliente.phone;//phone
        if(cliente.email != null)
            acc.Email__c = cliente.email;//email
        if(cliente.merc != null)
            acc.Mercado__c = cliente.merc;//mercado
        if(cliente.macro != null)
            acc.Marco__c = cliente.macro;//marco
        if(cliente.area != null)
            acc.Area__c = cliente.area;//area do cliente
        if(cliente.idioma != null)
            acc.Idioma__c = cliente.idioma;//idioma do cliente
        /*if(cliente.tipo_clientes != null)
acc.Tipologia_de_clientes__c = cliente.tipo_clientes;//tipologia de clientes*/
        if(cliente.email_docs != null)
            acc.Email_de_envio_de_documentos__c = cliente.email_docs;//email para envio de documentos
        if(cliente.moeda != null)
            acc.CurrencyIsoCode = cliente.moeda;//moeda ISO
        if(cliente.esc_standard != null)
            acc.Escalao_Standard__c = cliente.esc_standard;//escalao standard
        if(cliente.iban != null)
            acc.IBAN__c = cliente.iban;//iban
        if(cliente.notas != null)
            acc.Notas_PHC__c = cliente.notas;//notas
        //if(cliente.cliente_anterior != null) acc.Cliente_anterior__c = cliente.cliente_anterior;//cliente anterior
        //if(cliente.n_cliente_anterior != null) acc.N_Cliente_anterior = cliente.n_cliente_anterior;//numero de cliente anterior
        //if(cliente.tabela_ligacao_cliente != null) acc.Tabela_Ligacao_cliente__c = cliente.tabela_ligacao_cliente;//tabela de ligação entre clientes
        if(cliente.rappel != null)
            acc.Rappel__c = cliente.rappel.isNumeric() ? Decimal.valueOf(cliente.rappel) : 0;//rappel
        if(cliente.incentiv != null) acc.Incentivo__c = cliente.incentiv.isNumeric() ? Decimal.valueOf(cliente.incentiv) : 0;//incentivo
        if(cliente.catalogo != null) acc.Catalogo__c = cliente.catalogo.isNumeric() ? Decimal.valueOf(cliente.catalogo) : 0;//catalogo
        if(cliente.amostras != null) acc.Amostras__c = cliente.amostras.isNumeric() ? CurrencyConverter.convert(Decimal.valueOf(cliente.amostras), 'EUR', cliente.moeda) : 0;//amostras
        if(cliente.descefec != null) acc.Desconto_Efectivo__c = cliente.descefec;//desconto efectivo
        
        if(cliente.outro_email_doc != null && cliente.outro_email_doc != '') acc.Outro_email_de_envio_de_documentos__c = cliente.outro_email_doc;
        if(cliente.outro_email != null && cliente.outro_email != '') acc.Outro_email__c = cliente.outro_email;
        
        // 2018/07/19 - morada e sistema a facturar 
        // Sistema_a_faturar__c 
          if(cliente.sistemaFacturar != null && cliente.sistemaFacturar != '') acc.Sistema_a_faturar__c = cliente.sistemaFacturar;
        // Morada_principal__c         
         if(cliente.localentrega != null && cliente.localentrega != '') acc.Morada_principal__c = cliente.localentrega;
        //2018/08/23  - campo de codigo fiscal 
        if(cliente.codFiscal != null && cliente.codFiscal != '') acc.Codigo_fiscal__c = cliente.codFiscal;
        //2018/10/09  - atribuicao manual de zonas
        if(cliente.atribManual != null) acc.Atribuicao_zonas_manual__c = cliente.atribManual;

        try{
            checkRecursive.runAccount = false;
            upsert acc Numero_de_cliente__c;
        }catch(Exception ex){
            return new ClientUpsertResult(ex.getMessage(), '1', false,acc.Id);
        }
        return new ClientUpsertResult('0', '0', true,acc.Id);
    }
    
    global class ClientUpsertResult{
        webservice String error;
        webservice String error_type;
        webservice boolean result;
        webservice String salesforceId;
        
        global ClientUpsertResult(){}
        
        global ClientUpsertResult(String error, String error_type, boolean result, String salesforceId){
            this.error = error;
            this.error_type = error_type;
            this.result = result;
            this.salesforceId = salesforceId;
        }
    }
    
    global class Cliente {
        webservice Boolean bloqueado;//bloqueado
        webservice String no;//numero de cliente
        webservice Boolean inativo;//inativo
        webservice String tipo;//tipo de cliente
        webservice Boolean enc_canceladas;//encomendas canceladas
        webservice Boolean contencioso;//contencioso
        webservice String vendedor;//Vendedor
        webservice String tab_precos;//tabela de preços
        webservice Double obj_fat;//objectivo de faturação
        webservice Integer div_nao_titulada_maturidade;//divida nao titulada maturidade
        webservice Double div_nao_titulada_saldo;//divida nao titulada saldo
        webservice Integer div_titulada_maturidade;//divida titulada maturidade
        webservice Double div_titulada_saldo;//divida titulada saldo
        webservice Double lim_cred_comercial;//limite de credito comercial
        webservice Double lim_oper_divida;//limite operacional de divida
        webservice Double plafond_comercial;//plafond comercial
        webservice Double plafond_operacional;//plafond operacional
        webservice String tipo_fat;//tipo de faturação
        webservice Double tax_iva;//taxa de iva
        webservice String merc_cust;//mercado de customização
        webservice String nomeEmpresa;//nome da empresa
        webservice Integer tabIVA;//tabela de iva
        webservice String dir_comercial;//director comercial
        webservice String nomeab;//nome abreviado
        webservice String nif;//nif
        webservice String preNIF;//prefixo de nif
        webservice Double divida_vencida;//divida vencida
        webservice String escalao_hidea;//escalao hidea
        
        //Novos campos adicionados
        webservice String pais;//pais do cliente
        webservice String zona;//zona do cliente
        webservice String local;//localidade do cliente
        webservice String morada;//morada do cliente
        webservice String cod_post;//codigo postal do cliente
        webservice String vend_nome;//nome vendedor
        webservice String assistent;//assistente comercial
        webservice String doc_dest;//documento destino
        webservice String idioma_fat;//idioma de faturação
        webservice String website;//website
        webservice String phone;//phone
        webservice String email;//email
        webservice String merc;//mercado
        webservice String macro;//macro
        webservice String area;//area do cliente
        webservice String idioma;//idioma do cliente
        //webservice String tipo_clientes;//tipologia de clientes
        webservice String email_docs;//email para envio de documentos
        webservice String moeda;//moeda ISO
        webservice boolean esc_standard;//escalao standard
        webservice String iban;//iban
        webservice String notas;//notas
        webservice Boolean cliente_anterior;//cliente anterior
        webservice Decimal n_cliente_anterior;//numero de cliente anterior
        webservice String tabela_ligacao_cliente;//tabela de ligação entre clientes
        webservice String rappel;//rappel
        webservice String incentiv;//incentivo
        webservice String catalogo;//catalogo
        webservice String amostras;//amostras
        webservice Decimal obj;//objectivo
        webservice Decimal descefec;//descrição/desconto efectivo
        
        //2018-05-14
        webservice String outro_email_doc;//outro email para docs
        webservice String outro_email;//outro email
        
        //2018/07/19 
         webservice String localentrega; //Account.Morada_principal__c - Cl.localentrega
         webservice String sistemaFacturar; //Account.Sistema_a_faturar__c 
        
        // 2018/08/23
         webservice String codFiscal;  //Account.Codigo_fiscal__c
        
        // 2018/10/09
         webservice Boolean atribManual;  //Account.Atribuicao_manual__c
        
        // 2018/11/06
        webservice String salesforceId;  //adicionado para chamada externa apenas
        webservice String stamp;  //adicionado para chamada externa apenas
        
        
    }
    
    
    // contactos 
    // 2018/05/10
    webservice static ContactoResult contactUpsert(Contacto contacto){        
        
        system.debug(contacto);
        Contact  contactoPHC = new Contact ();
        
        // stamp de PHC 
        if(contacto.Stamp != null) contactoPHC.Stamp__c = contacto.Stamp;
        
        //numero de cliente
        if(contacto.no != null)	contactoPHC.Account = new Account(Numero_de_cliente__c = contacto.no); 
        
        // LastName
        if(contacto.UltimoNome != null && contacto.UltimoNome != ''){
            contactoPHC.LastName = contacto.UltimoNome;
            if(contacto.PrimeiroNome != null)
                contactoPHC.FirstName = contacto.PrimeiroNome;
        }else{
            contactoPHC.LastName = contacto.PrimeiroNome != null && contacto.PrimeiroNome != '' ? contacto.PrimeiroNome : 'Contacto sem nome';
        }
        
        // MobilePhone
        if(contacto.Telemovel != null)contactoPHC.MobilePhone = contacto.Telemovel;
        
        // Phone
        if(contacto.Telemovel != null)contactoPHC.Phone = contacto.Telefone;
        
        // Email
        if(contacto.Email != null)contactoPHC.Email = contacto.Email;
        
        // Fax
        if(contacto.Fax != null)contactoPHC.Fax = contacto.Fax;
        
        // Funcao__c
        if(contacto.Funcao != null)contactoPHC.Funcao__c = contacto.Funcao;
        
        if(contacto.IdSalesforce != null && contacto.IdSalesforce != '') contactoPHC.Id = contacto.IdSalesforce;
        
        try{
            checkRecursive.runContact = false;            
            
            if(contacto.IdSalesforce != null && contacto.IdSalesforce != '') {      
                try {
                    upsert contactoPHC id;
                }
                catch(Exception ex){
                    contactoPHC.Id = null;
                    if(contacto.Stamp != null && contacto.Stamp != '')  { upsert contactoPHC Stamp__c; } 
                    else {   
                        return new ContactoResult(ex.getMessage(), '1', false, contacto.IdSalesforce, contacto.Stamp); }
                }
            }
            else { 
                if(contacto.Stamp != null && contacto.Stamp != '')  { upsert contactoPHC Stamp__c; } 
                else {   return new ContactoResult('não foi possível nem por IDSalesForce, nem por Stamp', '1', false, contacto.IdSalesforce, contacto.Stamp); }
            } 
        }catch(Exception ex){
            return new ContactoResult(ex.getMessage(), '1', false, contacto.IdSalesforce, contacto.Stamp);
        }
        return new ContactoResult('0', '0', true, contactoPHC.id, contactoPHC.Stamp__c);
    }
    
    webservice static ContactoResult contactDelete(String IDSalesForce, String StampPHC){        
        
        system.debug('Recebi  IDSalesForce=' + IDSalesForce + '  StampPHC=' + StampPHC);
        checkRecursive.runContact = false;
        try{
            
            if(IDSalesForce != null && IDSalesForce != '') {
                
                
                Contact contacto = new Contact();
                contacto.id = IDSalesForce.trim();
                delete contacto;
            }else {
                if(StampPHC != null  && StampPHC != '') {
                    delete [Select id from Contact Where Stamp__c = :StampPHC.trim()];
                }else{
                    return new ContactoResult('Não foi enviada chave para executar a acção.', '1', false, IDSalesForce, StampPHC);
                }
            }
        }
        catch (DmlException e) {
            return new ContactoResult(e.getMessage(), '1', false, IDSalesForce, StampPHC);
        }
        catch(Exception ex){
            return new ContactoResult(ex.getMessage(), '1', false, IDSalesForce, StampPHC);
        }
        return new ContactoResult('0', '0', true, IDSalesForce, StampPHC);
    }
    
    
    global class ContactoResult{
        webservice String error;
        webservice String error_type;
        webservice boolean result;
        webservice String idSalesForce;
        webservice String StampPHC;
        
        
        global ContactoResult(String error, String error_type, boolean result, String idSalesForce , String StampPHC){
            this.error = error;
            this.error_type = error_type;
            this.result = result;
            this.idSalesForce = idSalesForce;
            this.StampPHC = StampPHC;
        }
    }
    
    global class Contacto {
        webservice String no;//numero de cliente
        webservice String PrimeiroNome ;  // FirstName
        webservice String UltimoNome ; //LastName
        webservice String Telemovel; // MobilePhone
        webservice String Telefone;  // Phone
        webservice String Email;       // Email
        webservice String Fax;   // Fax
        webservice String Stamp; // Stamp__c
        webservice String Funcao; // Funcao__c
        webservice String IdSalesforce;		// id 
    }
    
    
    // 2018/05/29
    // WebService UPSert MoradaCliente de PHC para SalesForce  :criar / actualizar Morada de Cliente 
    webservice static MoradaResult moradaClienteUpsert(MoradaCliente moradacli){        
        
        system.debug(moradacli);
        
        Morada_de_entrega__c  moradacliPHC = new Morada_de_entrega__c ();
        
        // stamp de PHC 
        if(moradacli.Stamp != null) moradacliPHC.Stamp__c = moradacli.Stamp;
        
        //numero de cliente
        if(moradacli.no != null) moradacliPHC.Conta__r = new Account(Numero_de_cliente__c = String.valueOf(moradacli.no)); 
        
        // Nome_da_empresa__c
        if(moradacli.entidade != null)moradacliPHC.Nome_da_empresa__c = moradacli.entidade;
        
        //Telefone_logistico__c 
        if(moradacli.telefone1 != null)moradacliPHC.Telefone_logistico__c = moradacli.telefone1;
        
        // MSEQ__c
        if(moradacli.seq != null) moradacliPHC.MSEQ__c =moradacli.seq.isNumeric() ? Decimal.valueOf(moradacli.seq) : null;
        
        // Morada_de_entrega__c
        if(moradacli.morada != null)moradacliPHC.Morada_de_entrega__c = moradacli.morada;
        
        // Localidade__c	
        if(moradacli.local != null)moradacliPHC.Localidade__c = moradacli.local;
        
        // Codigo_postal__c	
        if(moradacli.codpost != null)moradacliPHC.Codigo_postal__c = moradacli.codpost;
        
        // Pais__c	
        if(moradacli.pais != null)moradacliPHC.Pais__c = moradacli.pais;
        
        // Ao_cuidado_de__c	
        if(moradacli.ncontacto != null)moradacliPHC.Ao_cuidado_de__c = moradacli.ncontacto;
        
        //  String IdSalesforce;		 = 	id
        if(moradacli.IdSalesforce != null && moradacli.IdSalesforce != '') moradacliPHC.Id = moradacli.IdSalesforce;
        
        try{
            checkRecursive.runMoradaCliente = false;       
            
            if(moradacli.IdSalesforce != null && moradacli.IdSalesforce != '') {      
                try {
                    upsert moradacliPHC id;
                }
                catch(Exception ex){
                    moradacliPHC.Id = null;
                    if(moradacli.Stamp != null && moradacli.Stamp != '')  { upsert moradacliPHC Stamp__c; } 
                    else {   
                        return new MoradaResult(ex.getMessage(), '1', false, moradacli.IdSalesforce, moradacli.Stamp); }
                }
            }
            else { 
                if(moradacli.Stamp != null && moradacli.Stamp != '')  { upsert moradacliPHC Stamp__c; } 
                else {   return new MoradaResult('Não foi possível nem por IDSalesForce, nem por Stamp', '1', false, moradacli.IdSalesforce, moradacli.Stamp); }
            } 
        }catch(Exception ex){
            return new MoradaResult(ex.getMessage(), '1', false, moradacli.IdSalesforce, moradacli.Stamp);
        }
        return new MoradaResult('0', '0', true, moradacliPHC.id, moradacliPHC.Stamp__c);
    } 
    
    // 2018/05/24 
    // eliminar morada de Cliente    
    webservice static MoradaResult moradaClienteDelete(String IDSalesForce, String StampPHC){        
        
        system.debug('Recebi  IDSalesForce=' + IDSalesForce + '  StampPHC=' + StampPHC);
        
        try{
            
            if(IDSalesForce != null && IDSalesForce != '') {
                
                
                Morada_de_entrega__c morada = new Morada_de_entrega__c();
                morada.id = IDSalesForce.trim();
                delete morada;
            }else {
                if(StampPHC != null  && StampPHC != '') {
                    delete [Select id from Morada_de_entrega__c Where Stamp__c = :StampPHC.trim()];
                }else{
                    return new MoradaResult('Não foi enviada chave para executar a acção.', '1', false, IDSalesForce, StampPHC);
                }
            }
        }
        catch (DmlException e) {
            return new MoradaResult(e.getMessage(), '1', false, IDSalesForce, StampPHC);
        }
        catch(Exception ex){
            return new MoradaResult(ex.getMessage(), '1', false, IDSalesForce, StampPHC);
        }
        return new MoradaResult('0', '0', true, IDSalesForce, StampPHC);
    }
    
    
    global class MoradaResult{
        webservice String error;
        webservice String error_type;
        webservice boolean result;
        webservice String idSalesForce;
        webservice String StampPHC;
        
        
        global MoradaResult(String error, String error_type, boolean result, String idSalesForce , String StampPHC){
            this.error = error;
            this.error_type = error_type;
            this.result = result;
            this.idSalesForce = idSalesForce;
            this.StampPHC = StampPHC;
        }
    }
    
    global class MoradaCliente {
        webservice String no;//numero de cliente
        webservice String entidade ;  // Nome_da_empresa__c
        webservice String seq ; //MSEQ__c
        webservice String telefone1; // Telefone_logistico__c
        webservice String morada;  // Morada_de_entrega__c
        webservice String local;       // Localidade__c		
        webservice String codpost;   // Codigo_postal__c
        webservice String pais;   // Pais__c
        webservice String ncontacto;   // Ao_cuidado_de__c		
        webservice String Stamp; // Stamp__c
        webservice String IdSalesforce;		// 		id
    }
    
    webservice static ProductQCResult productInQC(String ref, boolean isInQC){
        /*List<Product2> prods = [Select Id From Product2 Where ProductCode = :ref And RecordType.DeveloperName = 'Produto'];
        if(!prods.isEmpty()){
            for(Product2 prod : prods){
                prod.Em_controlo_de_qualidade__c = isInQC;
            }
            try{
                update prods;
                return new ProductQCResult('', false);
            }catch(Exception ex){
                return new ProductQCResult(ex.getMessage(), true);
            }
        }else{
            return new ProductQCResult('Sem correspondência de referencia base.', true);
        }*/
        return new ProductQCResult('Método por implementar.', true);
    }
    
    global class ProductQCResult {
        webservice String errorMsg;
        webservice boolean error;
        
        global ProductQCResult(String errorMsg, boolean error){
            this.errorMsg = errorMsg;
            this.error = error;
        }
    }
}