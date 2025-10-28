#!/bin/sh
# Replace any author/committer with cnesmartcontract@gmail.com -> Yerins Abraham
if [ "$GIT_AUTHOR_EMAIL" = "cnesmartcontract@gmail.com" ]; then
  export GIT_AUTHOR_NAME='Yerins Abraham'
  export GIT_AUTHOR_EMAIL='yerinssaibs@gmail.com'
fi
if [ "$GIT_COMMITTER_EMAIL" = "cnesmartcontract@gmail.com" ]; then
  export GIT_COMMITTER_NAME='Yerins Abraham'
  export GIT_COMMITTER_EMAIL='yerinssaibs@gmail.com'
fi
