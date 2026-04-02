package upendra.bajpai.background_locator_neo.provider

import java.util.HashMap

interface LocationUpdateListener {
    fun onLocationUpdated(location: HashMap<Any, Any>?)
}
