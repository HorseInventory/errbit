# Git stash IF there are unstaged changes
HAS_UNSTAGED_CHANGES=$(git diff --name-only | grep -q . && echo true || echo false)

if [ "$HAS_UNSTAGED_CHANGES" = "true" ]; then
  git add .
  git stash
fi

git checkout h_main
git rebase main
git push -f heroku h_main:main
git checkout main

# IF there were stashed changes, apply them
if [ "$HAS_UNSTAGED_CHANGES" = "true" ]; then
  git stash pop
fi
