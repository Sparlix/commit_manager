#!/bin/bash
directory="/home/xypnox/Projects/self/commit_manager"
cd $directory

branch=`date +%F`

branch_exists=`git show-ref refs/heads/${branch}`
num_changes=`git status --porcelain=v1 2>/dev/null | wc -l`

git-is-merged () {
  # I am using the following bash function like: 
  # git-is-merged develop feature/new-feature
  # https://stackoverflow.com/a/49434212/
  
  merge_destination_branch=$1
  merge_source_branch=$2

  merge_base=$(git merge-base $merge_destination_branch $merge_source_branch)
  merge_source_current_commit=$(git rev-parse $merge_source_branch)
  if [[ $merge_base = $merge_source_current_commit ]]
  then
    echo $merge_source_branch is merged into $merge_destination_branch
    return 0
  else
    echo $merge_source_branch is not merged into $merge_destination_branch
    return 1
  fi
}


create_commit() {
  local gstatus=`git status --porcelain`

  if [ ${#gstatus} -ne 0 ]
  then
    echo "Committing and pushing changes!"
    git add --all
    git commit -m "Auto Commit" -m "Porecellain: $gstatus"
  fi
}


commit_and_push() {
  git checkout $1
  
  create_commit

  git push origin $1
}

commit_and_push_set_tracking() {
  git checkout $1
  
  create_commit

  git push -u origin $1
}

create_squash_commit_push() {
  # Create squash commit from $1
  git checkout main

  git merge --squash $1

  create_commit

  git push origin main
}

prev_check() {
  local prev_branch=`date -d "yesterday" +%F`
  local prev_branch_exists=`git show-ref refs/heads/${prev_branch}`

  if [ -n "$prev_branch_exists" ]; then
    echo "Prev branch not deleted, processing!"
    
    git-is-merged main $prev_branch
    is_merged=$?
    echo $is_merged
    
    if [ $is_merged -eq 0 ]; then
      echo "$prev_branch merged"
    else
      echo "$prev_branch not merged"
      commit_and_push $prev_branch
      create_squash_commit_push $prev_branch
    fi
    
    # Delete prev day's branch
    git checkout main
    git branch -D $prev_branch
    git push --delete origin $prev_branch

  else
    echo "Prev branch doesn't exist skipping"
  fi
  
}

main() {

  echo -e "\n\n===Running Script===\n :at $0 \n :on $(date) \n :with $num_changes changes \n"

  prev_check

  if [ -n "$branch_exists" ]; then
    echo 'Daily Branch exists!'
    # Commit all stuff here
    commit_and_push $branch
  else
    echo "Daily Branch doesn't exist!"
    git checkout main
    git checkout -b $branch
    commit_and_push_set_tracking $branch
  fi
}

main

