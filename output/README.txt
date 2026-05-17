ArchFusion BIM — canonical reference sources (copy into WCS-BIM target as needed).

output/Models.swift          — 8 core @Model types (canonical schema)
output/AppShellView.swift    — tab shell with NavigationStack per tab

Live app:
  WCS-BIM/Data/Models/*.swift     — extended models (elementType, exportPackages, SiteContext, …)
  WCS-BIM/Presentation/Integration/IntegrationLayer.swift — AppShellView + tab containers

App entry: WCS-BIM/WCS_BIMApp.swift (typealias ArchFusionBIMApp)
