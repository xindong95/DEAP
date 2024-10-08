# trim adapter module

# ================================
# @auther: Xin Dong
# @email: xindong9511@gmail.com
# @date: Sep 2019
# ================================

trim_threads = config['trim_threads']
# global RES_PATH
# RES_PATH = config['RES_PATH']

def getTrimFastq(wildcards):
    if wildcards.sample in config['samples']:
        s = config['samples'][wildcards.sample]
    return s


def trim_targets(wildcards):
    ls = []
    for run in config["runs"]:
        if config["runs"][run]["type"] == "RS" and config["runs"][run]['samples']:
            for sample in config["runs"][run]['samples']:
                # print(run,sample)
                # for paired-end data, will generate val1 and val2
                if len(config['samples'][sample]) == 2:
                    ls.append('%s/trim/%s/%s_val_1.fq.gz' % (RES_PATH, sample, sample))
                    ls.append('%s/trim/%s/%s_val_2.fq.gz' % (RES_PATH, sample, sample))
                else:
                    ls.append('%s/trim/%s/%s_trimmed.fq.gz' % (RES_PATH, sample, sample))
                    ls.append('%s/trim/%s/%s_trimmed_fastqc.zip' % (RES_PATH, sample, sample))
                    ls.append('%s/trim/%s/%s_trimmed_fastqc.html' % (RES_PATH, sample, sample))
    return ls


rule trim_PairedEndAdapter:
    input:
        getTrimFastq
    output:
        '%s/trim/{sample}/{sample}_val_1.fq.gz' % RES_PATH,
        '%s/trim/{sample}/{sample}_val_2.fq.gz' % RES_PATH,
    params:
        quality=20,
        error_rate=0.1,
        stringency=8,
        length=20,
        output_dir=lambda wildcards: '%s/trim/%s/' % (RES_PATH, wildcards.sample),
        # file=lambda wildcards, input: '--paired %s %s' % (input[0],input[1]) if len(input) == 2 else '%s' % input, 
        basename=lambda wildcards: '%s' % wildcards.sample
    log: "%s/logs/trim/{sample}_trim_PairedEndAdapter.log" % RES_PATH
    message: "TRIM: Trim adaptor for paired-end sample - {wildcards.sample} " 
    threads: trim_threads
    shell:
        "trim_galore -q {params.quality} -j {threads} --phred33 --stringency {params.stringency} "
        "-e {params.error_rate} --gzip --length {params.length} --fastqc "
        "--basename {params.basename} -o {params.output_dir} --paired {input} > {log} 2>&1 "

rule trim_SingleEndAdapter:
    input:
        getTrimFastq
    output:
        '%s/trim/{sample}/{sample}_trimmed.fq.gz' % RES_PATH,
        '%s/trim/{sample}/{sample}_trimmed_fastqc.zip' % RES_PATH,
        '%s/trim/{sample}/{sample}_trimmed_fastqc.html' % RES_PATH,
    params:
        quality=20,
        error_rate=0.1,
        stringency=8,
        length=20,
        output_dir=lambda wildcards: '%s/trim/%s/' % (RES_PATH, wildcards.sample),
        basename=lambda wildcards: '%s' % wildcards.sample
    log: "%s/logs/trim/{sample}_trim_SingleEndAdapter.log" % RES_PATH
    message: "TRIM: Trim adaptor for paired-end sample - {wildcards.sample} "
    threads: trim_threads
    shell:
        "trim_galore -q {params.quality} -j {threads} --phred33 --stringency {params.stringency} "
        "-e {params.error_rate} --gzip --length {params.length} --fastqc "
        "{input} --basename {params.basename} -o {params.output_dir} > {log} 2>&1"


