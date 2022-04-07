


configfile: "config.json"


def get_fa_inputs(wildcards):
    inputs = []
    for g, info in config['assemblies'].items():
        inputs.append("data/input_genomes/{g}/{fa}"
                      "".format(g=g,
                                fa=info['fn_fna']))
    return(inputs)

rule all:
    input:
        "data/input.fa"
        
"""
https://github.com/pangenome/PanSN-spec
uses this hack https://github.com/ekg/fastix
"""
rule make_fa:
    input:
        get_fa_inputs
    output:
        fa_out="data/input.fa"
    run:
        fastix="/global/home/users/psudmant/code/fastix/target/debug/fastix"
        shell("> {fa_out}".format(fa_out=output.fa_out))
        for g, info in config['assemblies'].items():
            print(g)
            fn_fna=info['fn_fna']
            shell("zcat data/input_genomes/{g}/{fn_fna} |"
                  " {fastix} "
                  " --prefix {g}# "
                  " /dev/stdin "
                  " >>{fa_out}"
                  "".format(fn_fna=fn_fna,
                            fastix=fastix,
                            g=g,
                            fa_out=output.fa_out))
        

rule download:
    output:
        "data/input_genomes/{g}/{fn_fna}"
    run:
        ftp_path = config['assemblies'][wildcards.g]["fn_ftp"]
        shell("wget -O {fn_out} {ftp_path}".format(fn_out=output[0],
                                                   ftp_path=ftp_path))
