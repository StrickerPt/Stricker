public class c_ImportarPrecosCliente {
    public String retURL {get;set;}
    public String accId {get;set;}
    public String accNo {get;set;}
    public String selectedOperation {get;set;}
    public boolean includeClients {get;set;}
    public String blobFile {get;Set;}
    public String fileName {get;Set;}
    public boolean isSucess {get;set;}
    public String msgErro {get;set;}
    public static String separador {get{return '+++';}set;}
    
    public c_ImportarPrecosCliente(ApexPages.StandardSetController std){
        
        if(std.getRecord() instanceof Preco_por_cliente__c){
            accId = ApexPages.currentPage().getParameters().get('id');
            accNo = [Select Id, Numero_de_cliente__c From Account Where Id = :accId].Numero_de_cliente__c;
            includeClients = false;
            isSucess = false;
            selectedOperation = 'insert';
            retURL = accId;
        }else{
            retURL = ApexPages.currentPage().getParameters().get('retURL');
            includeClients = true;
            isSucess = false;
            selectedOperation = 'insert';
        }
    }
    
    public List<SelectOption> getOperations(){
        List<SelectOption> operations = new List<SelectOption>();
        operations.add(new selectOption('insert', 'Insert'));
        operations.add(new selectOption('delete', 'Delete'));
        //@toDo: descomentar para apagar todos os preços por cliente
        /*List<Profile_Id__mdt> profiles = [Select Id__c From Profile_Id__mdt Where DeveloperName = 'Administrador_do_sistema' Limit 1];
        if(!profiles.isEmpty()){
            if(profiles.get(0).Id__c == UserInfo.getProfileId()){
				operations.add(new selectOption('deleteAll', 'Delete All'));
            }
        }*/
        return operations;
    }
    
    public void processFile(){
        msgErro = '';
        isSucess = false;
        blobFile= blobFile.substring(blobFile.indexOf(',')+1);
        
        /*********************************************************INSERT******************************************************/
        if(selectedOperation == 'insert'){
            Set<String> s_no = new Set<String>();
            Set<String> s_prodCode = new Set<String>();
            List<TempPPC> temporary = new List<TempPPC>();
            
            //LER FICHEIRO
            try{
                String[] m_Filelines = EncodingUtil.base64Decode(blobFile).toString().split('\n');
                if(m_Filelines.size() <= 5001){
                    
                    for (Integer i = 1 ; i < m_Filelines.size() ; i++){
                        List<String> m_LineValues = new List<String>();
                        
                        m_LineValues = m_Filelines[i].split(';');
                        if(m_LineValues.size()>0){
                            Integer index = 0;
                            TempPPC temp = new TempPPC();

                            if(!includeClients){
                                if(m_LineValues.size() == 4){
                                    index = -1;
                                    temp.no = accNo;
                                }else{
                                    msgErro += 'Numero errado de colunas, por favor valide o formato do ficheiro.';
                                    return;
                                }
                            }else{
                                if(m_LineValues.size() == 5){
                                    temp.no = m_LineValues[index];
                                }else{
                                    msgErro += 'Numero errado de colunas, por favor valide o formato do ficheiro.';
                                    return;
                                }
                            }
                            //ORGANIZAR FICHEIRO NA ESTRUTURA
                            temp.prodCode = m_LineValues[index + 1];
                            temp.value = m_LineValues[index + 2];
                            temp.startDate = parseDate(m_LineValues[index + 3]);
                            temp.endDate = parseDate(m_LineValues[index + 4]);
                            
                            temporary.add(temp);
                            
                            system.debug(temp.prodCode);
                            //PREPARAR SETS PARA OS SELECTS
                            s_no.add(temp.no);
                            s_prodCode.add(temp.prodCode);
                            
                        }else{
                            msgErro += 'Não foram encontrados valores na linha' + i + ' no ficheiro, por favor reveja o mesmo.' + separador;
                        }
                    }
                }else{
                    msgErro += 'Por favor limite o ficheiro a 5000 linhas.';
                    return;
                }
            }catch(Exception ex){
                msgErro += 'Erro de leitura do ficheiro, por favor valide o formato do mesmo: ' + ex.getMessage() + separador;
                system.debug(ex.getMessage());
                UtilClaims.sendEmailFailure('Falha importação de preços por cliente', msgErro + ex.getMessage() + '; linha:' + ex.getLineNumber());
                return;
            }
            
            //MAPAS PARA IDS CONTAS (Key:Numero_de_cliente__c, self)
            Map<String, Account> accMap = buildAccountsMap(s_no);
            
            //MAPAS PARA IDS PRODUTOS (Key:ProductCode-Tamanho__c, self)
            Map<String, Product2> prodMap = buildProdMap(s_prodCode);
            
            List<Preco_por_cliente__c> ppcs = new List<Preco_por_cliente__c>();
            Integer counter = 2;//COMEÇA NO 2 POR CAUSA DO CABEÇALHO DAS COLUNAS
            //MAPEAMENTO PARA A TABELA PRECOS_POR_CLIENTE__C
            for(TempPPC temp : temporary){
                if(!accMap.containsKey(temp.no) || !prodMap.containsKey(temp.prodCode)){
                    if(!accMap.containsKey(temp.no)){
                        msgErro += 'Cliente ' + temp.no + ' não encontrado. Linha: ' + counter + separador;
                    }
                    if(!prodMap.containsKey(temp.prodCode)){
                        msgErro += 'Produto ' + temp.prodCode + ' não encontrado. Linha: ' + counter + separador;
                    }
                }else{
                    Preco_por_cliente__c ppc = new Preco_por_cliente__c();
                    
                    ppc.Cliente__c = accMap.get(temp.no).Id;
                    ppc.CurrencyIsoCode = accMap.get(temp.no).CurrencyIsoCode;
                    ppc.Produto__c = prodMap.get(temp.prodCode).Id;
                    String valor = temp.value.contains(',') ? temp.value.replace(',', '.') : temp.value;
                    ppc.Valor__c = Decimal.valueOf(valor);
                    ppc.Data_de_inicio__c = temp.startDate;
                    ppc.Data_de_fim__c = temp.endDate;
                    
                    ppcs.add(ppc);
                }
                counter++;
            }
            try{
                //INSERT NA TABELA
                if(!ppcs.isEmpty()){
                    if(msgErro == '') insert ppcs;
                }else{
                    msgErro += 'Não foram identificadas linhas no ficheiro, por favor valide o mesmo.' + separador;
                    return;
                }
                isSucess = true;
            }catch(DMLException ex){
                msgErro += 'Erro de criação das linhas: ' + ex.getDmlMessage(0) + separador;
                UtilClaims.sendEmailFailure('Falha importação de preços por cliente', msgErro + ex.getMessage() + '; linha:' + ex.getLineNumber());
                return;
            }
        }/*********************************************************DELETE******************************************************/
        else if(selectedOperation == 'delete'){
            //LER FICHEIRO
            try{
                Set<String> s_binomio = new Set<String>();
                String[] m_Filelines = EncodingUtil.base64Decode(blobFile).toString().split('\n');
                for (Integer i = 1 ; i < m_Filelines.size() ; i++){
                    String[] m_LineValues = new String[]{};
                        m_LineValues = m_Filelines[i].split(';');
                    if(m_LineValues.size()>0){
                        if(!includeClients){
                            s_binomio.add(accNo + m_LineValues[0]);
                        }else{
                            s_binomio.add(m_LineValues[0] + m_LineValues[1]);
                        }
                        //CRIAR BINOMIO PARA SELECT 
                    }else{
                        msgErro += 'Não foram encontrados valores na linha' + i + ' no ficheiro, por favor reveja o mesmo.' + separador;
                    }
                }
                //DELETE DA TABELA
                if(!s_binomio.isEmpty()){
                    delete [Select id From Preco_por_cliente__C Where Chave__c In :s_binomio];
                }else{
                    msgErro += 'Não foram identificadas linhas no ficheiro, por favor valide o mesmo.\n';
                    return;
                }
                isSucess = true;
            }catch(Exception ex){
                msgErro += 'Erro de leitura do ficheiro, por favor valide o formato do mesmo: ' + ex.getMessage() + separador;
                UtilClaims.sendEmailFailure('Falha importação de preços por cliente', msgErro + ex.getMessage() + '; linha:' + ex.getLineNumber());
                return;
            }
        }
    }
    
    public Map<String, Account> buildAccountsMap(Set<String> s_no){
        Map<String, Account> accMap = new Map<String, Account>();
        //get accounts
        for(Account acc : [Select Id, Numero_de_cliente__c, CurrencyIsoCode From Account Where Numero_de_cliente__c In :s_no]){
            accMap.put(acc.Numero_de_cliente__c, acc);
        }
        return accMap;
    }
    
    public Map<String, Product2> buildProdMap(Set<String> s_prodCode){
        Map<String, Product2> prodMap = new Map<String, Product2>();
        //get products
        for(Product2 prod : [Select Id, ProductCode, Tamanho__c From Product2 Where ChaveExterna__c In :s_prodCode]){
            prodMap.put(prod.ProductCode + (prod.Tamanho__c != '' && prod.Tamanho__c != null ? '-' + prod.Tamanho__c : ''), prod);
        }
        return prodMap;
    }
    
    public Date parseDate(String inDate){
        if(inDate == null){
            return null;
        }else{
            Date dateRes = null;
            List<String> splittedDate = null;
            
            if(inDate.contains('/')){
                splittedDate = inDate.split('/');
            }else if(inDate.contains('-')){
                splittedDate = inDate.split('-');
            }
            
            if(splittedDate != null){
                
                if(splittedDate[0].trim().length() == 4){
                    dateRes = Date.newInstance(Integer.valueOf(splittedDate[0].trim()),
                                               Integer.valueOf(splittedDate[1].trim()),
                                               Integer.valueOf(splittedDate[2].trim()));
                }else if(splittedDate[2].trim().length() == 4){
                    dateRes = Date.newInstance(Integer.valueOf(splittedDate[2].trim()),
                                               Integer.valueOf(splittedDate[1].trim()),
                                               Integer.valueOf(splittedDate[0].trim()));
                }
            }
            return dateRes;
        }
    }
    
    public class TempPPC{
        public String prodCode;
        public String no;
        public String value;
        public Date startDate;
        public Date endDate;
        
        public String binomio;
        
        public TempPPC(){}
    }
}