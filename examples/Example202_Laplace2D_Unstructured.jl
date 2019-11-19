#=

# 202: 2D Laplace equation on unstructured mesh

=#
module Example202_Laplace2D_Unstructured

using VoronoiFVM
using LinearAlgebra

if installed("PyPlot")
    using PyPlot
end


# Flux function which describes the flux
# between neigboring control volumes $\omega_k$ and $\omega_l$
function flux!(f,u,edge,data)
    uk=viewK(edge,u)  
    ul=viewL(edge,u)
    f[1]=uk[1]-ul[1]
end

function source!(f,edge,data)
    f[1]=1
end


function main(;plotgrid=false, doplot=false,nref=0)

    nspecies=1
    ispec=1
    nrad=10*2^nref
    grid=VoronoiFVM.Grid(points=reduce(hcat,[ [cos(2*pi*i/nrad), sin(2*pi*i/nrad)] for i=1:nrad]),
                         bfaces=reduce(hcat,vcat([ [i,i+1] for i=1:nrad-1],[[nrad,1]])),                  
                         bfaceregions=ones(nrad),
                         regionpoints=[0.0 0.0;],
                         regionnumbers=[1],
                         regionvolumes=[0.1*2.0^(-2*nref)])

    if plotgrid
        PyPlot.clf()
        fvmpyplot(grid)
        return
    end

    
    # Create a physics structure
    physics=VoronoiFVM.Physics(num_species=nspecies,flux=flux!,source=source!)

    # Create a finite volume system with dense storage of unknowns
    sys=VoronoiFVM.DenseSystem(grid,physics)

    # Enable species 1 in region 1
    enable_species!(sys,ispec,[1])

    # Set boundary conditions
    # Dirichlet boundary conditions are marked by setting a corresponding value of the
    # boundary factor
    for i=1:num_bfaceregions(grid)
        sys.boundary_factors[ispec,i]=VoronoiFVM.Dirichlet
        sys.boundary_values[ispec,i]=0
    end
    
    # Create & initialize array for solution and initial value
    inival=unknowns(sys)
    solution=unknowns(sys)
    inival.=0
    solution.=0

    # Solve stationary problem
    solve!(solution,inival,sys)
    
    if doplot
        PyPlot.clf()
        fvmpyplot(grid, solution[1,:])
    end
    
    # Return test value
    return norm(solution,Inf)
end

#
# Called by unit test
#
function test()
    main() ≈ 0.22723115735932964
end

end
