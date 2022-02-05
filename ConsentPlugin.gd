extends Node

onready var root = get_parent() # main scene
onready var p_options = root.get_node("HUD2/Options")

enum CONSENT_STATUS {
	UNKNOWN,
	NON_PERSONALIZED,
	PERSONALIZED
}

var consent
var age = 0


func check_consent():
	if Engine.has_singleton("ConsentPlugin"):
		consent = Engine.get_singleton("ConsentPlugin")
		# connect signals
		consent.connect("consent_info_updated",self,"consent_info_updated")
		consent.connect("failed_to_update_consent_information",self,"failed_to_update_consent_information")
		consent.connect("consent_form_loaded",self,"consent_form_loaded")
		consent.connect("consent_form_opened",self,"consent_form_opened")
		consent.connect("consent_form_closed",self,"consent_form_closed")
		consent.connect("consent_form_error",self,"consent_form_error")
		# pass your own publisher ids as a string array to the plugin
		var publisherIds = ["pub-1234567890123456"]
		consent.requestConsentInformation(publisherIds)


func consent_info_updated(consent_status):
	match consent_status:
		CONSENT_STATUS.UNKNOWN:
			# Obtain user consent by showing a form
			obtain_consent()
		CONSENT_STATUS.NON_PERSONALIZED:
			#configure AdMob implementation for non personalized apps
			configure_admob_non_personalized()
		CONSENT_STATUS.PERSONALIZED:
			#configure AdMob implementation for personalized apps
			configure_admob_personalized()


func configure_admob_non_personalized():
	print("GDPR - non personalized ads")
	root.admob.is_personalized = false
	root.admob.init()
	root.load_ads()
  	# c_updategdpr is a button hidden by default for non european users
	p_options.c_updategdpr.show() # will show for european user to update their choice


func configure_admob_personalized():
	print("GDPR - personalized ads")
	root.admob.is_personalized = true
	root.admob.init()
	root.load_ads()
	# c_updategdpr is a button hidden by default for non european users
	p_options.c_updategdpr.show() # will show for european user to update their choice


func failed_to_update_consent_information(error_description):
	print(error_description)
	configure_admob_personalized()


func obtain_consent():
	# Replace this string value with your own privacy policy url
	var privacy_url = "https://bouncymarble.github.io/privacy-policy.html"
	# Add the choice to select personalized ads to the form
	var with_personalized_ads_option = true
	# Add the choice to select non personalized ads to the form
	var with_non_personalized_ads_option = true
	# Add the choice to pay for an ad free version, handled in consent_form_closed
	var with_ad_free_option = false
	consent.buildConsentForm(privacy_url, with_personalized_ads_option , with_non_personalized_ads_option , with_ad_free_option)
	consent.loadConsentForm()


func consent_form_loaded():
	print("GDPR consent form loaded")
	# don't show for children under 13
	if age > 12:
		consent.showConsentForm()
	else:
		configure_admob_non_personalized()


func consent_form_opened():
	print("GDPR consent form opened")


func consent_form_closed(consent_status, _user_prefers_ad_free):
	print("GDPR consent form closed")
	consent_info_updated(consent_status)


func consent_form_error(error_description):
	print("GDPR "+error_description)
	root.load_ads()
