public class ExtraInfo {
    public Decimal qtt_total {get;set;}
    public Decimal qtt_reclamada {get;set;}
    public Decimal unit_price {get;set;}
    public Decimal unit_priceOriginal {get;set;}
    public Decimal total_price {get;set;}
    public String num_dos {get;set;}
    public String pais_cli {get;set;}
    public String pais_ent {get;set;}
    public Decimal total_doc {get;set;}
    public String tab_iva_cli {get;set;}
    public String tab_iva_fat {get;set;}
    public String tab_iva_dos {get;set;}
    public DateTime dat_pro {get;set;}
    public String tec {get;set;}
    public Decimal n_imp {get;set;}
    public Decimal n_rep {get;set;}
    public String v_maquete {get;set;}
    public String bostamp {get;set;}
    public String nome_rem {get;set;}
    public String morada {get;set;}
    public String transp {get;set;}
    public DateTime dat_exp {get;set;}
    public String num_for {get;set;}
    public String nom_for {get;set;}
    public String lote {get;set;}
    public DateTime dat_enc {get;set;}
    public String num_ast {get;set;}
    public DateTime dat_efe_enc {get;set;}
    public String img_link {get;set;}
    public String refSF {get;set;}
    public DateTime dat_maq {get;set;}
    public String transEnc {get;set;}
    public String tracking {get;set;}
    
    public ExtraInfo(wsdl_Claims.Parecer extra){
        Datetime nullDate = Datetime.newInstance(1900, 1, 1);
        this.qtt_total = extra.qtt_total;
        this.qtt_reclamada = extra.qtt_reclamada;
        this.unit_price = extra.unit_price;
        this.unit_priceOriginal = extra.unit_priceOriginal;
        this.total_price = extra.total_price;
        this.num_dos = extra.num_dos;
        this.pais_cli = extra.pais_cli;
        this.pais_ent = extra.pais_ent;
        this.total_doc = extra.total_doc;
        this.tab_iva_cli = extra.tab_iva_cli;
        this.tab_iva_fat = extra.tab_iva_fat;
        this.tab_iva_dos = extra.tab_iva_dos;
        this.dat_pro = extra.dat_pro > nullDate ? extra.dat_pro : null;
        this.tec = extra.tec;
        this.n_imp = extra.n_imp;
        this.n_rep = extra.n_rep;
        this.v_maquete = extra.v_maquete;
        this.bostamp = extra.bostamp;
        this.nome_rem = extra.nome_rem;
        this.morada = extra.morada;
        this.transp = extra.transp;
        this.dat_exp = extra.dat_exp > nullDate ? extra.dat_exp : null;
        this.num_for = extra.num_for;
        this.nom_for = extra.nom_for;
        this.lote = extra.lote;
        this.dat_enc = extra.dat_enc > nullDate ? extra.dat_enc : null;
        this.num_ast = extra.num_ast;
        this.dat_efe_enc = extra.dat_efe_enc > nullDate ? extra.dat_efe_enc : null;
        this.img_link = extra.img_link;
        this.refSF = extra.refSF;
        this.dat_maq = extra.dat_maq > nullDate ? extra.dat_maq : null;
        this.transEnc = extra.transEnc;
        this.tracking = extra.tracking;
    }
}