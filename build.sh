echo "Showing file contents to know what to add to .dockerignore:"
echo `ls -l`

docker build -t cruglobal/$PROJECT_NAME:$GIT_COMMIT-$BUILD_NUMBER .
