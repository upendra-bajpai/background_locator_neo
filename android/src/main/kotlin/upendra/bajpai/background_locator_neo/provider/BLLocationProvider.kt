package upendra.bajpai.background_locator_neo.provider

interface BLLocationProvider {
    var listener: LocationUpdateListener?

    fun removeLocationUpdates()

    fun requestLocationUpdates(request: LocationRequestOptions)
}

