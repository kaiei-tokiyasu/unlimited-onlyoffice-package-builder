#!/bin/bash

# Set version as a variable
VERSION="9.1.0.54"

# Function to perform git operations
function git_operations {
    local repo_dir=$1
    local version=$2
    local branch_name="${version}-kaiei-tokiyasu"
    local tag_name="v${version}-kaiei-tokiyasu"

    # Navigate to the repository directory
    cd "$repo_dir" || exit

    # Checkout master and sync with upstream
    git checkout master
    git pull upstream-origin master
    git fetch --all --tags

    #git checkout master
    #git pull --rebase
    git branch -D $branch_name
    git tag -d $tag_name

    git push origin --delete "$branch_name"
    git push --delete origin "$tag_name"

    # Checkout the specific version tag and create a new branch
    git checkout tags/v$version -b $branch_name

}

function git_push {
    local repo_dir=$1
    local version=$2
    local branch_name="${version}-kaiei-tokiyasu"
    local tag_name="v${version}-kaiei-tokiyasu"

    cd "$repo_dir" || exit

    git push origin $branch_name
    git tag -a $tag_name -m "$branch_name"
    git push origin $tag_name
}

# Update build_tools repository
git_operations "/root/onlyoffice_repos/build_tools" "$VERSION"
#copy py3 to fix build

git checkout master -- tools/linux/python3.tar.gz
git add tools/linux/python3.tar.gz
git commit -m 'fix-build'

# Cherry-pick commit in build_tools
git cherry-pick f88a3ba5470664888bbf150d67ef0b31f74a6cbb

git checkout --theirs scripts/base.py
git add scripts/base.py

git checkout --theirs configure.py
git add configure.py

git cherry-pick --continue
git commit -m 'fix-conflict'

# Update base.py with version-specific values
sed -i "s/unlimited_organization = \"btactic-oo\"/unlimited_organization = \"kaiei-tokiyasu\"/g" scripts/base.py
sed -i "s/unlimited_tag_suffix = \"-btactic\"/unlimited_tag_suffix = \"-kaiei-tokiyasu\"/g" scripts/base.py

# Commit changes in build_tools
git add scripts/base.py
git commit --amend --no-edit

# Push changes and create a tag
git_push "/root/onlyoffice_repos/build_tools" "$VERSION"

# Update server repository
git_operations "/root/onlyoffice_repos/server" "$VERSION"

# Cherry-pick commit in server
git cherry-pick 81db34dee17f8a6a364669232a8c7c2f5d36d81f


# Push changes and create a tag in server
git_push "/root/onlyoffice_repos/server" "$VERSION"

# Update web-apps repository
git_operations "/root/onlyoffice_repos/web-apps" "$VERSION"

# Cherry-pick commit in web-apps
git cherry-pick 140ef6d1d687532dcb03b05912838b8b4cf161a3

git status
git diff

#git cherry-pick --continue
#git commit --allow-empty

# Push changes and create a tag in web-apps
git_push "/root/onlyoffice_repos/web-apps" "$VERSION"

# Update unlimited-onlyoffice-package-builder repository
cd ~/onlyoffice_repos/unlimited-onlyoffice-package-builder || exit
git checkout main
git push origin main
git pull main
git fetch --all --tags

nano onlyoffice-package-builder.sh

git add onlyoffice-package-builder.sh

# Create and push a new tag for the package builder
PACKAGE_TAG="builds-debian-11/$VERSION"

git commit -m "update custom commits sha $PACKAGE_TAG"

#git branch -D $PACKAGE_TAG
git tag -d $PACKAGE_TAG

#git push origin --delete "$PACKAGE_TAG"
git push --delete origin "$PACKAGE_TAG"

git tag -a $PACKAGE_TAG -m "$PACKAGE_TAG"
git push origin $PACKAGE_TAG

echo "All steps completed for version $VERSION"
