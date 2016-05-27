#/usr/bin/env bash

# git clone steps
# ---------------

git clone	https://github.com/datagovuk/ckan
cd ckan
git checkout release-v2.2-dgu
git remote add ckan https://github.com/ckan/ckan
cd -

git clone	https://github.com/ckan/ckanext-archiver
cd ckanext-archiver
git checkout c1e42065d349e668fb668ed7e494e50d08b37c74 .
cd -

git clone	https://github.com/datagovuk/ckanext-certificates
cd ckanext-certificates
git checkout 2835acd5b7fa669feff620b574bcff72d1cfc108 .
cd -

git clone	https://github.com/datagovuk/ckanext-datapreview
cd ckanext-datapreview
git checkout 42e0d3e195e6a17e9f28ee8153d9d483bd91b4fd .
cd -

git clone	https://github.com/datagovuk/ckanext-dcat
cd ckanext-dcat
git checkout dgu
cd -

git clone	https://github.com/zvetaM/ckanext-dgu
cd ckanext-dgu
git checkout master
ln -s ../commit-msg.githook ./.git/hooks/commit-msg
cd -

git clone	https://github.com/datagovuk/ckanext-dgu-local
cd ckanext-dgu-local
git checkout 81abd6f31fd5a51e8443a52b2048fcd1f592d259 .
cd -

git clone	https://github.com/datagovuk/ckanext-ga-report
cd ckanext-ga-report
git checkout c4051cb6a937b793b3c89703f0a5e9d19b8a651d .
cd -

git clone	https://github.com/datagovuk/ckanext-harvest
cd ckanext-harvest
git checkout 2.0
cd -

git clone	https://github.com/datagovuk/ckanext-hierarchy
cd ckanext-hierarchy
git checkout 5456d755fbe40823249fd20f71108b89cd917d28 .
cd -

git clone	https://github.com/datagovuk/ckanext-packagezip
cd ckanext-packagezip
git checkout cb5ecfba3f02e995b5975c8345e98b2e5ea7b322 .
cd -

git clone	https://github.com/datagovuk/ckanext-os
cd ckanext-os
git checkout master
cd -

git clone	https://github.com/ckan/ckanext-qa
cd ckanext-qa
git checkout master
cd -

git clone https://github.com/datagovuk/ckanext-report
cd ckanext-report
git checkout 3156c9db68bd663a08357cabf03eb01667e969e9 .
cd -

git clone	https://github.com/datagovuk/ckanext-spatial
cd ckanext-spatial
git checkout dgu
cd -

git clone	https://github.com/datagovuk/ckanext-taxonomy
cd ckanext-taxonomy
git checkout a23b08623214b11b09fdad8960d33b91469ea61d .
cd -

git clone	https://github.com/okfn/ckanext-importlib
cd ckanext-importlib
git checkout 7992df7f47265c3f24d41d6ef8a6345084e85c7d .
cd -

git clone	https://github.com/zvetaM/shared_dguk_assets
cd shared_dguk_assets
git checkout master
cd -

git clone   https://github.com/datagovuk/logreporter
cd logreporter
git checkout d06501cf11702692f46f33d7c723a03e4b0cafd4 .
cd -

git clone   https://github.com/zvetaM/dgu_d7
cd dgu_d7
git checkout master
cd -

