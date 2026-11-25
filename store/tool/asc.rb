# encoding: utf-8
# A small App Store Connect API client for the Ìe Bắc Âu listing (app 6838730847): metadata, category,
# age rating, screenshots, price, availability, review notes, build and the internal TestFlight group.
# It needs an API key file: ASC_KEY_PATH, or ~/.appstoreconnect/private_keys/AuthKey_<ASC_KEY_ID>.p8.
#
#   ASC_KEY_ID=… ASC_ISSUER_ID=… ruby store/tool/asc.rb get /v1/apps/6838730847
#   … ruby store/tool/asc.rb listing        # name, subtitle, texts, URLs, categories, copyright
#   … ruby store/tool/asc.rb age            # age rating: health/wellness topic, everything else none
#   … ruby store/tool/asc.rb screenshots    # store/screenshots/iphone/*.png and ipad/*.png
#   … ruby store/tool/asc.rb price          # free
#   … ruby store/tool/asc.rb availability   # every territory
#   … ruby store/tool/asc.rb review         # notes for App Review (+ contact from ASC_CONTACT_* if set)
#   … ruby store/tool/asc.rb build          # attach the newest processed build
#   … ruby store/tool/asc.rb testflight EMAIL FIRST LAST   # internal group "Nội bộ" with that team member
#
# Only Ruby's standard library is used (macOS Ruby 2.6 is enough). Run it from the repository root.
# Nothing here submits for review: that stays a manual step in App Store Connect.

require "openssl"
require "json"
require "net/http"
require "base64"
require "digest"
require "uri"

APP_ID = ENV.fetch("ASC_APP_ID", "6838730847")
KEY_ID = ENV.fetch("ASC_KEY_ID")
ISSUER = ENV.fetch("ASC_ISSUER_ID")
KEY_PATH = ENV["ASC_KEY_PATH"] || File.expand_path("~/.appstoreconnect/private_keys/AuthKey_#{KEY_ID}.p8")
SITE = "https://nhatbien.github.io/xikebacau-privacy"
LOCALE = "vi"
APP_VERSION = ENV.fetch("APP_VERSION", "1.0.0")

def b64(data)
  Base64.urlsafe_encode64(data, padding: false)
end

# ES256 JWT, valid for 15 minutes.
def token
  key = OpenSSL::PKey.read(File.read(KEY_PATH))
  head = b64({ alg: "ES256", kid: KEY_ID, typ: "JWT" }.to_json)
  now = Time.now.to_i
  body = b64({ iss: ISSUER, iat: now, exp: now + 900, aud: "appstoreconnect-v1" }.to_json)
  der = key.sign(OpenSSL::Digest.new("SHA256"), "#{head}.#{body}")
  r, s = OpenSSL::ASN1.decode(der).value.map { |n| n.value.to_s(2).rjust(32, "\0") }
  "#{head}.#{body}.#{b64(r + s)}"
end

def api(method, path, payload = nil)
  uri = URI(path.start_with?("http") ? path : "https://api.appstoreconnect.apple.com#{path}")
  req = Net::HTTP.const_get(method.capitalize).new(uri)
  req["Authorization"] = "Bearer #{token}"
  if payload
    req["Content-Type"] = "application/json"
    req.body = payload.to_json
  end
  res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |h| h.request(req) }
  data = res.body.to_s.empty? ? {} : JSON.parse(res.body)
  unless res.code.to_i.between?(200, 299)
    detail = (data["errors"] || []).map { |e| "#{e["code"]}: #{e["detail"]}" }.join("; ")
    raise "#{method.upcase} #{uri.path} -> #{res.code} #{detail}"
  end
  data
end

def patch(type, id, attributes)
  api(:patch, "/v1/#{type}/#{id}", { data: { type: type, id: id, attributes: attributes } })
end

LISTING = File.read("store/listing-vi.md", encoding: "utf-8")
def block(title)
  LISTING[/\*\*#{Regexp.escape(title)}.*?\*\*\s+```\n(.*?)\n```/m, 1] or raise "#{title} missing in store/listing-vi.md"
end
NAME = LISTING[/^- App name .*?: `(.+?)`/, 1]

# The iOS version being prepared. A new app starts with "1.0"; it is renamed to the build's own version.
def version
  versions = api(:get, "/v1/apps/#{APP_ID}/appStoreVersions?filter[platform]=IOS")["data"]
  v = versions.find { |x| x["attributes"]["versionString"] == APP_VERSION } ||
      versions.find { |x| x["attributes"]["appStoreState"] == "PREPARE_FOR_SUBMISSION" }
  raise "no editable version" unless v
  if v["attributes"]["versionString"] != APP_VERSION
    v = patch("appStoreVersions", v["id"], { versionString: APP_VERSION })["data"]
  end
  v
end

def version_localization(v)
  api(:get, "/v1/appStoreVersions/#{v["id"]}/appStoreVersionLocalizations")["data"].find { |l| l["attributes"]["locale"] == LOCALE } or
    raise "no #{LOCALE} localization on the version"
end

def app_info
  infos = api(:get, "/v1/apps/#{APP_ID}/appInfos")["data"]
  infos.find { |i| !%w[READY_FOR_DISTRIBUTION READY_FOR_SALE].include?(i["attributes"]["state"] || i["attributes"]["appStoreState"]) } || infos.first
end

def listing
  info = app_info
  loc = api(:get, "/v1/appInfos/#{info["id"]}/appInfoLocalizations")["data"].find { |l| l["attributes"]["locale"] == LOCALE }
  patch("appInfoLocalizations", loc["id"], { name: NAME, subtitle: block("Subtitle"), privacyPolicyUrl: "#{SITE}/privacy/" })
  puts "app info: name #{NAME}, subtitle, privacy policy URL"

  api(:patch, "/v1/appInfos/#{info["id"]}", { data: { type: "appInfos", id: info["id"], relationships: {
    primaryCategory: { data: { type: "appCategories", id: "HEALTH_AND_FITNESS" } },
    secondaryCategory: { data: { type: "appCategories", id: "LIFESTYLE" } }
  } } })
  puts "categories: Health & Fitness, Lifestyle"

  v = version
  texts = { description: block("Description"), keywords: block("Keywords"), promotionalText: block("Promotional text"),
            supportUrl: "#{SITE}/support/", marketingUrl: "#{SITE}/" }
  patch("appStoreVersionLocalizations", version_localization(v)["id"], texts)
  puts "version #{APP_VERSION}: description (#{texts[:description].length} chars), keywords (#{texts[:keywords].length}), promo (#{texts[:promotionalText].length}), URLs"
  patch("appStoreVersions", v["id"], { copyright: "#{Time.now.year} Mai Biên" })
  puts "copyright set"
end

# A breathing and relaxation app: the health/wellness topic is yes, everything else none/false.
def age_rating
  decl = api(:get, "/v1/appInfos/#{app_info["id"]}/ageRatingDeclaration")["data"]
  skip = %w[kidsAgeBand ageRatingOverride ageRatingOverrideV2 koreaAgeRatingOverride developerAgeRatingInfoUrl
            gracRatingClassificationNumber]
  booleans = %w[gambling unrestrictedWebAccess lootBox advertising ageAssurance healthOrWellnessTopics messagingAndChat
                parentalControls userGeneratedContent socialNetworking datingAndRelationships sharedLocation
                socialMedia socialMediaAgeRestricted]
  answers = {}
  decl["attributes"].each do |name, value|
    next if skip.include?(name)
    answers[name] = (booleans.include?(name) || value == true || value == false) ? false : "NONE"
  end
  answers["healthOrWellnessTopics"] = true if answers.key?("healthOrWellnessTopics")
  patch("ageRatingDeclarations", decl["id"], answers)
  puts "age rating: #{answers.size} answers, health/wellness topic yes, the rest none/false"
end

SCREEN_SETS = { "iphone" => "APP_IPHONE_67", "ipad" => "APP_IPAD_PRO_3GEN_129" }

def screenshots
  vloc = version_localization(version)
  sets = api(:get, "/v1/appStoreVersionLocalizations/#{vloc["id"]}/appScreenshotSets")["data"]
  SCREEN_SETS.each do |dir, display|
    set = sets.find { |s| s["attributes"]["screenshotDisplayType"] == display }
    set ||= api(:post, "/v1/appScreenshotSets", { data: { type: "appScreenshotSets",
      attributes: { screenshotDisplayType: display },
      relationships: { appStoreVersionLocalization: { data: { type: "appStoreVersionLocalizations", id: vloc["id"] } } } } })["data"]
    have = api(:get, "/v1/appScreenshotSets/#{set["id"]}/appScreenshots")["data"].map { |s| s["attributes"]["fileName"] }
    Dir["store/screenshots/#{dir}/*.png"].sort.each do |path|
      name = "#{dir}-#{File.basename(path)}"
      next puts("#{name}: already there") if have.include?(name)
      bytes = File.binread(path)
      shot = api(:post, "/v1/appScreenshots", { data: { type: "appScreenshots",
        attributes: { fileName: name, fileSize: bytes.bytesize },
        relationships: { appScreenshotSet: { data: { type: "appScreenshotSets", id: set["id"] } } } } })["data"]
      shot["attributes"]["uploadOperations"].each do |op|
        uri = URI(op["url"])
        req = Net::HTTP::Put.new(uri)
        op["requestHeaders"].each { |h| req[h["name"]] = h["value"] }
        req.body = bytes.byteslice(op["offset"], op["length"])
        res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |h| h.request(req) }
        raise "upload #{name}: #{res.code}" unless res.code.to_i.between?(200, 299)
      end
      patch("appScreenshots", shot["id"], { uploaded: true, sourceFileChecksum: Digest::MD5.hexdigest(bytes) })
      puts "#{name}: uploaded (#{display})"
    end
  end
end

def attach_build
  v = version
  build = api(:get, "/v1/builds?filter[app]=#{APP_ID}&filter[processingState]=VALID&filter[preReleaseVersion.version]=#{APP_VERSION}&sort=-uploadedDate&limit=1")["data"].first
  raise "no processed build yet" unless build
  api(:patch, "/v1/appStoreVersions/#{v["id"]}/relationships/build", { data: { type: "builds", id: build["id"] } })
  puts "version #{APP_VERSION}: build #{build["attributes"]["version"]} attached"
end

# Free, with Vietnam as the base territory.
def price_free
  points = api(:get, "/v1/apps/#{APP_ID}/appPricePoints?filter[territory]=VNM&limit=200")["data"]
  free = points.find { |pt| pt["attributes"]["customerPrice"].to_f.zero? }
  raise "no free price point" unless free
  api(:post, "/v1/appPriceSchedules", {
    data: { type: "appPriceSchedules", relationships: {
      app: { data: { type: "apps", id: APP_ID } },
      baseTerritory: { data: { type: "territories", id: "VNM" } },
      manualPrices: { data: [{ type: "appPrices", id: "${free}" }] }
    } },
    included: [{ type: "appPrices", id: "${free}", attributes: { startDate: nil },
                 relationships: { appPricePoint: { data: { type: "appPricePoints", id: free["id"] } } } }]
  })
  puts "price: free (base territory Vietnam)"
end

# Every territory except China mainland (it needs a security assessment and an AIGC filing), and new ones as
# Apple adds them. The API wants every territory named.
def availability
  ids = api(:get, "/v1/territories?limit=200")["data"].map { |t| t["id"] }
  api(:post, "/v2/appAvailabilities", {
    data: { type: "appAvailabilities", attributes: { availableInNewTerritories: true }, relationships: {
      app: { data: { type: "apps", id: APP_ID } },
      territoryAvailabilities: { data: ids.map { |t| { type: "territoryAvailabilities", id: "${#{t}}" } } }
    } },
    included: ids.map do |t|
      { type: "territoryAvailabilities", id: "${#{t}}", attributes: { available: t != "CHN" },
        relationships: { territory: { data: { type: "territories", id: t } } } }
    end
  })
  puts "availability: #{ids.size - 1} of #{ids.size} territories (not China mainland)"
end

# Notes for App Review (with the invite code). The contact comes from ASC_CONTACT_FIRST, _LAST, _PHONE and
# _EMAIL: personal data, never written to the repository.
def review_notes
  v = version
  attributes = { notes: block("Review notes"), demoAccountRequired: false }
  { contactFirstName: "ASC_CONTACT_FIRST", contactLastName: "ASC_CONTACT_LAST",
    contactPhone: "ASC_CONTACT_PHONE", contactEmail: "ASC_CONTACT_EMAIL" }.each do |name, var|
    attributes[name] = ENV[var] if ENV[var] && !ENV[var].empty?
  end
  existing = api(:get, "/v1/appStoreVersions/#{v["id"]}/appStoreReviewDetail")["data"]
  if existing
    patch("appStoreReviewDetails", existing["id"], attributes)
  else
    api(:post, "/v1/appStoreReviewDetails", { data: { type: "appStoreReviewDetails", attributes: attributes,
      relationships: { appStoreVersion: { data: { type: "appStoreVersions", id: v["id"] } } } } })
  end
  puts "review notes set (#{attributes[:notes].length} chars), #{attributes.size - 2} contact fields"
end

# Internal TestFlight group that gets every build, with one team member as tester.
def testflight(email, first, last)
  groups = api(:get, "/v1/apps/#{APP_ID}/betaGroups")["data"]
  group = groups.find { |g| g["attributes"]["isInternalGroup"] && g["attributes"]["name"] == "Nội bộ" }
  group ||= api(:post, "/v1/betaGroups", { data: { type: "betaGroups",
    attributes: { name: "Nội bộ", isInternalGroup: true, hasAccessToAllBuilds: true },
    relationships: { app: { data: { type: "apps", id: APP_ID } } } } })["data"]
  puts "internal group: #{group["attributes"]["name"]} (#{group["id"]})"
  return unless email
  existing = api(:get, "/v1/betaGroups/#{group["id"]}/betaTesters")["data"].map { |t| t["attributes"]["email"] }
  return puts("tester already in the group") if existing.include?(email)
  api(:post, "/v1/betaTesters", { data: { type: "betaTesters", attributes: { email: email, firstName: first, lastName: last },
    relationships: { betaGroups: { data: [{ type: "betaGroups", id: group["id"] }] } } } })
  puts "tester added to the group"
end

case ARGV[0]
when "get" then puts JSON.pretty_generate(api(:get, ARGV[1]))
when "listing" then listing
when "age" then age_rating
when "screenshots" then screenshots
when "build" then attach_build
when "price" then price_free
when "availability" then availability
when "review" then review_notes
when "testflight" then testflight(ARGV[1], ARGV[2], ARGV[3])
else abort "usage: ruby store/tool/asc.rb get|listing|age|screenshots|build|price|availability|review|testflight"
end
