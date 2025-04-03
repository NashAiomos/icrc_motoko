启动
cd code/icrc_motoko
export PATH="$PATH:/home/neutronstarpro/npm/bin"
source ~/.bashrc
dfx start --background --clean
dfx deploy icrc --argument '( record {                    
    name = "aaa";
    symbol = "aaa";
    decimals = 8;
    fee = 1_000;
    max_supply = 100_000_000_000_000;
    initial_balances = vec {
        record {
            record {
                owner = principal "hbvut-2ui4m-jkj3c-ey43g-lbtbp-abta2-w7sgj-q4lqx-s6mrb-uqqd4-mqe";
                subaccount = null;
            };
            100_000_000_000_000
        };
    };
    min_burn_amount = 10_000;
    minting_account = opt record {
        owner = principal "hbvut-2ui4m-jkj3c-ey43g-lbtbp-abta2-w7sgj-q4lqx-s6mrb-uqqd4-mqe";
        subaccount = null;
    };
    advanced_settings = null;
})'

<br>

安装 mops 但是没有用：检查环境变量。
```
~/code/icrc1_motoko$ mops --version
mops：未找到命令

# 检查 mops 文件是否存在
~/code/icrc1_motoko$ ls /home/neutronstarpro/npm/bin/mops
/home/neutronstarpro/npm/bin/mops # 存在

# 添加环境变量
~/code/icrc1_motoko$ export PATH="$PATH:/home/neutronstarpro/npm/bin"

# 保存
~/code/icrc1_motoko$ source ~/.bashrc
```
