/* @Autor: Marco Galvão
 * @Ultima Modificação: Marco Galvão
 * Controlador do componente de escolha do documento financeiro a reclamar
 * @numCli : recebido por parametro "no" representa o numero do cliente que está a reclamar
 * @choice : decisão do utilizador para o documento base para a reclamação. Valores possiveis são "DOCS" e "DOSS"; Este valor define se o serviço chamado é de documentos ou de dossiers;
 * @ftstamp : Stamp do ficheiro selecionado pelo utilizador; Escolhido neste componente e é passado para a página principal para continuar o processo;
 * @bostamp : Stamp do dossier selecionado pelo utilizador; Escolhido neste componente caso  seja escolhido a opção de dossier;
 * @docs : Lista de documentos/dossiers com um ficheiro associado possivel de ser reclamado;
 * @isChosen : variável que define se o utilizador já escolheu o objecto base pelo qual quer chegar ao documento financeiro
 * @faturas : Lista temporária que contém as várias faturas associadas ao dossier selecionado pelo utilizador
 * */
public class c_ChooseOrigin {
    public String numCli {get;set;}
    public String choice {get;set;}
    public String ftstamp {get;set;}
    public String bostamp {get;set;}
    public String selectedLine {get;set;}
    public boolean showBackPageButton {get;set;}
    public List<UtilClaims.NewClaimLine> docs {get;set;}
    public List<UtilClaims.NewClaimLine> originalDocs {get;set;}
    public boolean isChosen {get;set;}
    public List<UtilClaims.Fatura> faturas {get;set;}
    public String filter {get;set;}
    public boolean choiceSucess {get;set;}
    
    public c_ChooseOrigin(){
        choiceSucess = true;
        isChosen = false;
        docs = new List<UtilClaims.NewClaimLine>();
        originalDocs = new List<UtilClaims.NewClaimLine>();
        faturas = new List<UtilClaims.Fatura>();
    }
    
    /* Chama o serviço correspondente para mostrar os documentos possiveis de serem reclamados
     * recebe da página como parametros:
     * @choice: variável com o valor selecionado
     * */
    public void getDocuments(){
        try{
            choiceSucess = true;
            filter = '';
            originalDocs.clear();
            if(choice == 'DOCS'){
                //chama serviço de documentos
                docs = IntegratorClaims.getDocs(numCli);
            }else if(choice == 'DOSS'){
                //chama serviço de dossiers
                docs = IntegratorClaims.getDoss(numCli);
            }
            if(!docs.isEmpty()) originalDocs.addAll(docs);
            isChosen = true;
        }catch(Exception ex){
            choiceSucess = false;
        }
    }
    
    /* Faz reset à variável para voltar a mostrar o painel de escolha, permite a alteração do objecto base ao utilizador;
     * */
    public void goBack(){
        isChosen = false;
    }
    
    /* Percorre as linhas mostradas ao utilizador e seleciona a linha escolhida, para guardar o seu stamp, de maneira a poder ser chamado o serviço que devolve as linhas apenas daquele documento financeiro;
     * @docs : lista mostrada ao utilizador;
     * */
    public void checkLines(){
        for(UtilClaims.NewClaimLine doc : docs){
            system.debug(doc);
            //procura a linha selecionada
            if(doc.selected){
                //se for um dossier com mais do que um documento associado procura qual destes documentos foi selecionado;
                if(faturas.size() > 1){
                    for(UtilClaims.Fatura fat : faturas){
                        if(fat.selected){
                            //selectedLine = doc;
                            doc.ftstamp = fat.ftstamp;
                            doc.bostamp = fat.bostamp;
                            selectedLine = JSON.serialize(doc);
                            break;
                        }
                    }
                }
                //se 
                //apenas tiver um documento associado ou for directamente um documento financeiro;
                else{
                    selectedLine = JSON.serialize(doc);
                }
            }
        }
    }
    
    /* Ao selecionar um dossier com mais do que um documento financeiro associado esta lista é construida apenas com estes documentos para que seja selecionado apenas um destes documentos;
     * @faturas : lista mostrada dos documentos associados ao dossier selecionado ao utilizador;
     * */
    public void buildShowFaturas(){
        faturas.clear();
        for(UtilClaims.NewClaimLine doc : docs){
            //procura o dossier selecionado;
            if(doc.selected){
                faturas.addAll((List<UtilClaims.Fatura>) JSON.deserialize(doc.fats, List<UtilClaims.Fatura>.class));
            }
        }
    }
    
    /*
     * */
    public void filterList(){
        docs.clear();
        List<UtilClaims.NewClaimLine> filteredDocs = new List<UtilClaims.NewClaimLine>();
        for(UtilClaims.NewClaimLine line : originalDocs){
            boolean match = false;
            //chamar método compareValues por cada campo necessário comparar
            for(String field : UtilClaims.compareDocFields){
                match = match || UtilClaims.compareValues(line.get(field), filter);
                if(match){
                    filteredDocs.add(line);
                    break;
                }
            }
        }
        docs.addAll(filteredDocs);
    }
}