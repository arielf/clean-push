#
# Makefile for handy 3-letter-shortcuts:
#    	-- Starting letter:
#	Targets starting with 'd' are diff
#	Targets starting with 's' are sync (push/pull)
#
#	-- middle letter (remote: 'r', origin 'o', local: 'l')
#	Targets with middle 'o' (origin) or 'r' are vs remote
#	Targets with middle 'l' vs local
#
#	-- Last letter:
#	'm' refers to main/master branch
#	'f' refers to feature (dev) branch
#
# Examples:
# 	dm == dlm == diff local master
# 	drf == dof == diff remote (origin) feature branch
#
MB = main
FB = dev

all: 3way-sync		#-- top level make target

.PHONY: help dm dm dof drf dom drm help s3 3way-sync

dm dlm:			#-- git diff vs local master
	#
	# check that our $(FB) branch is identical to $(MB)
	#
	git diff $(MB)

dof drf:		#-- git diff vs remote (origin) feature branch
	#
	# check that our $(FB) branch is identical to the _remote_ $(FB)
	#
	git diff remotes/origin/$(FB)

dom drm:		#-- git diff vs remote (origin) master
	#
	# check that our $(FB) branch is identical to the _remote_ $(MB)
	#
	git diff remotes/origin/$(MB)


#
# sync remotes
#
sof srf:		#-- push to remote (origin) feaure branch
	git push -f

slm sm:			#-- pull in local master
	#
	# Get latest into local $(MB)
	#
	git checkout $(MB) && git pull -f && git checkout $(FB)

srm som:		#-- pull remote $(MB) -> local $(FB)
	#
	# pull remote $(MB) -> local $(MF)
	#
	git pull origin $(MB)

s3 3way-sync:		#-- 3-way sync (remote+local $(MB) -> $(FB))
	#
	# 3-way sync
	#
	$(MAKE) slm
	$(MAKE) som
	$(MAKE) srf

h help:           	#-- print (this) help on top-level Makefile targets
	#
	# Supported top-level make targets
	#
	@grep -- '[#]--' $(MAKEFILE_LIST)
