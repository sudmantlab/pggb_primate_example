


configfile: "config.json"



rule all:
    input:
        "data/out/multiqc_config.yaml"
       
rule run_pggb:
    input:
        fa_in="data/input.fa.gz"
        #fa_idx="data/input.fa.fai"
    output:
        out="data/out/multiqc_config.yaml"
    run:
        pggb_path="/global/scratch2/psudmant/software/pggp/pggb_curr"
        PWD="/global/scratch2/psudmant/projects/pggb/pggb_primate_example"
        cmd = ("singularity "
               #"run -B ${{PWD}}/data:/data {pggb_path} "
               "run -B {PWD}/data:/data {pggb_path} "
               "\"pggb -i /data/input.fa.gz "
               "-p 95 "
               "-s 50000 "
               "-n 4 "
               "-t 24 "
               "-o /data/out "
               #"-M -C cons,100,1000,10000 -m\""
               "-M -m\""
               "".format(pggb_path=pggb_path,
                         PWD=PWD))
        print(cmd)
        shell(cmd)
        """
        Singularity> smoothxg -t 24 -T 24 -g /data/out//input.fa.gz.c55a916.7bdde5a.2a74e36.smooth.1.gfa -w 18028 -X 100 -I .8500 -R 0 -j 0 -e 0 -l 4507 -P 1,19,39,3,81,1 -O 0.03 -Y 400 -d 0 -D 0 -m /data/out//input.fa.gz.c55a916.7bdde5a.2a74e36.smooth.maf -Q Consensus_ -C /data/out//input.fa.gz.c55a916.7bdde5a.2a74e36.cons,cons,100,1000,10000 -o /data/out//input.fa.gz.c55a916.7bdde5a.2a74e36.smooth.gfa
        """


def get_fa_idxs(wildcards):
    inputs = []
    for g, info in config['assemblies'].items():
        inputs.append("data/input_genomes/{g}/idx.txt"
                      "".format(g=g))
    return(inputs)

"""
https://github.com/pangenome/PanSN-spec
uses this hack https://github.com/ekg/fastix
"""
rule make_input_fa:
    input:
        get_fa_idxs
    output:
        fa_out="data/input.fa.gz"
    run:
        fastix="/global/home/users/psudmant/code/fastix/target/debug/fastix"
        fastatools="~/code/fastatools/target/debug/fastatools"
        shell("> {fa_out}".format(fa_out=output.fa_out.replace(".gz","")))
        assemblies = config['contig_communities']['asssembly_order']
        for contig_com, contigs in config['contig_communities']['communities'].items():
            for i,contig in enumerate(contigs):
                curr_assembly = assemblies[i] 
                fn_fna=config['assemblies'][curr_assembly]['fn_fna'].replace(".gz","")
                shell("{fastatools} "
                      "extract "
                      "data/input_genomes/{g}/{fn_fna} "
                      "{contig} | "
                      "{fastix} "
                      "--prefix {g}# "
                      "/dev/stdin "
                      ">>{fa_out}"
                      "".format(fn_fna=fn_fna,
                                fastix=fastix,
                                fastatools=fastatools,
                                contig=contig,
                                g=curr_assembly,
                                fa_out=output.fa_out.replace(".gz","")))
        shell("bgzip {fa_out}".format(fa_out = output.fa_out.replace(".gz","")))
        shell("samtools faidx {fa_out}".format(fa_out = output.fa_out))

"""        
rule index_fa:
    input:
        fa_in="data/input.fa.gz"
    output: 
        fa_idx="data/input.fa.fai"
    shell:
        "samtools faidx {input.fa_in}"
"""        

def get_fa(wildcards):
    inputs = []
    inf = config['assemblies'][wildcards.g]
    ret = ("data/input_genomes/{g}/{fa}"
           "".format(g=wildcards.g,
                    fa=inf['fn_fna']).replace(".gz",""))
    return(ret)

rule get_fa_idx:
    input:
        get_fa
    output:
        idx_out = "data/input_genomes/{g}/idx.txt"
    run:
        cmd = ("~/code/fastatools/target/debug/fastatools "
               "index "
               "{fa_input} "
               "> {output} "
               "".format(fa_input=input[0],
                         output=output[0]))
        shell(cmd)
                                    
rule gunzip_fa:
    input:
        fa_gz_in ="data/input_genomes/{g}/{fn_fna}.fna.gz"
    output:
        fa_gz_out ="data/input_genomes/{g}/{fn_fna}.fna"
    shell:
        "gunzip {input.fa_gz_in}"

rule download:
    output:
        "data/input_genomes/{g}/{fn_fna}.fna.gz"
    run:
        ftp_path = config['assemblies'][wildcards.g]["fn_ftp"]
        shell("wget -O {fn_out} {ftp_path}".format(fn_out=output[0],
                                                   ftp_path=ftp_path))
