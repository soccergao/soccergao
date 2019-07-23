# git命令
## 远程仓库管理
git clone git&#64;github.com:soccergao/soccergao.git 克隆

git remote -v 查看远程服务器地址和仓库名称

git remote show origin 查看远程服务器仓库状态

git remote add origin git&#64;github.com:soccergao/soccergao.git 添加一个新的远程 Git 仓库

git remote set-url origin git&#64;github.com:soccergao/soccergao.git  设置远程仓库地址(用于修改远程仓库地址) 

git remote rename origin origin1 修改一个远程仓库的简写名

git remote rm origin 移除一个远程仓库

git push origin --delete &lt;branchName> 删除远程分支
## 分支
#### branch
git branch 查看本地所有分支

git branch &lt;file&gt; 创建分支

git commit --amend 改写单次commit
#### push
git push -f &lt;remote> &lt;branch> 强制push，覆盖原有远程仓库
git push origin master push到origin的master分支
#### checkout
git checkout &lt;file> 切换分支

git checkout -b &lt;file> 创建并切换分支

git checkout -d &lt;file> 删除分支

git checkout --&lt;file> 将在工作区的修改全部撤销

git checkout &lt;commit> -- &lt;file>获取历史版本的某个文件

#### reset
git reset HEAD &lt;file> 把暂存区的修改回退到工作区(HEAD表示最新的版本)

git reset --hard HEAD 回退到最新版本,等于删除工作区和暂存区的内容

git reset --hard HEAD^ 回退到上一次commit

git reset --hard e348162 回退到指定commit id版本(id可以不写完整)

注：HEAD最新版本, HEAD^ HEAD~1上一版本. 以此类推.

   --soft: 缓存区和工作目录都不会被改变(退到缓存区)
   
   --mixed: 默认选项。缓存区和你指定的提交同步, 但工作目录不受影响(退到工作区)
   
   --hard: 缓存区和工作目录都同步到你指定的提交(提交记录全部清除)
   
#### revert
git revert &lt;commit> 创建一个回退提交, 同git reset --hard &lt;commit>类似, 区别在于前者通过提交新的commit回到指定版本, 后者为指针直接回退
#### merge
git merge &lt;branch> merge分支
#### rebase
git rebase &lt;branch>同git merge &lt;branch>类似,

它的原理是回到两个分支最近的共同祖先, 根据当前分支(也就是要进行变基的分支)后续的历次提交对象, 
生成一系列文件补丁, 然后以基底分支最后一个提交对象为新的出发点, 逐个应用之前准备好的补丁文件, 
最后会生成一个新的合并提交对象, 从而改写提交历史, 使它成为直接下游
注: 合并结果中最后一次提交所指向的快照, 无论是通过变基, 还是三方合并, 都会得到相同的快照内容,
只不过提交历史不同罢了. 变基是按照每行的修改次序重演一遍修改, 而合并是把最终结果合在一起

git rebase -i HEAD~3 合并分支 之后会进入git vim界面
## 暂存管理stash
git stash 缓存工作区

git stash list 查看缓存列表

git stash apply 取出最近一次缓存

git stash apply stash@{n} 取出指定缓存

git stash apply --index

git stash drop 删除最近一次缓存

git stash drop stash@{n} 删除指定缓存

git stash pop 取出最近一次缓存并在缓存列表中删除该缓存

git stash show -p stash@{0} | git apply -R

git stash show -p | git apply -R

## 查看文件diff
git diff &lt;file> # 比较当前文件和暂存区文件差异 

git diff &lt;id1>&lt;id1>&lt;id2>  比较两次提交之间的差异

git diff &lt;branch1>..&lt;branch2> 在两个分支之间比较

git diff --staged 比较暂存区和版本库差异

git diff --cached 比较暂存区和版本库差异

git diff --stat # 仅仅比较统计信息
## 日志log
git log / git log -g / git reflog 查看历史操作记录
