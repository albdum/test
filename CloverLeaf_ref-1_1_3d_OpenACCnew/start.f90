!Crown Copyright 2012 AWE.
!
! This file is part of CloverLeaf.
!
! CloverLeaf is free software: you can redistribute it and/or modify it under 
! the terms of the GNU General Public License as published by the 
! Free Software Foundation, either version 3 of the License, or (at your option) 
! any later version.
!
! CloverLeaf is distributed in the hope that it will be useful, but 
! WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or 
! FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more 
! details.
!
! You should have received a copy of the GNU General Public License along with 
! CloverLeaf. If not, see http://www.gnu.org/licenses/.

!>  @brief Main set up routine
!>  @author Wayne Gaudin
!>  @details Invokes the mesh decomposer and sets up chunk connectivity. It then
!>  allocates the communication buffers and call the chunk initialisation and
!>  generation routines. It calls the equation of state to calculate initial
!>  pressure before priming the halo cells and writing an initial field summary.
!test

MODULE generate_on_device_module

CONTAINS

SUBROUTINE generate_on_device(c,x_min,x_max,y_min,y_max,z_min,z_max,&
                              density0, &
                              density1, &
                              energy0, &
                              energy1, &
                              pressure, &
                              soundspeed, &
                              viscosity, &
                              xvel0, &
                              yvel0, &
                              zvel0, &
                              xvel1, &
                              yvel1, &
                              zvel1, &
                              vol_flux_x, &
                              vol_flux_y, &
                              vol_flux_z, &
                              mass_flux_x, &
                              mass_flux_y, &
                              mass_flux_z, &
                              volume, &
                              cellx, &
                              celly, &
                              cellz, &
                              celldx, &
                              celldy, &
                              celldz, &
                              vertexx, &
                              vertexdx, &
                              vertexy, &
                              vertexdy, &
                              vertexz, &
                              vertexdz, &
                              xarea, &
                              yarea, &
                              zarea, &
                              left_snd_buffer, &
                              left_rcv_buffer, &
                              right_snd_buffer, &
                              right_rcv_buffer, &
                              bottom_snd_buffer, &
                              bottom_rcv_buffer, &
                              top_snd_buffer, &
                              top_rcv_buffer, &
                              back_snd_buffer, &
                              back_rcv_buffer, &
                              front_snd_buffer, &
                              front_rcv_buffer)

  USE data_module
  USE clover_module
  USE parse_module
  USE update_halo_module
  USE ideal_gas_module

  IMPLICIT NONE

INTEGER :: c,x_min,x_max,y_min,y_max,z_min,z_max

  REAL(KIND=8), DIMENSION(x_min-2:x_max+2,y_min-2:y_max+2,z_min-2:z_max+2)    :: density0
  REAL(KIND=8), DIMENSION(x_min-2:x_max+2,y_min-2:y_max+2,z_min-2:z_max+2) :: density1
  REAL(KIND=8), DIMENSION(x_min-2:x_max+2,y_min-2:y_max+2,z_min-2:z_max+2) :: energy0
  REAL(KIND=8), DIMENSION(x_min-2:x_max+2,y_min-2:y_max+2,z_min-2:z_max+2) :: energy1
  REAL(KIND=8), DIMENSION(x_min-2:x_max+2,y_min-2:y_max+2,z_min-2:z_max+2) :: soundspeed
  REAL(KIND=8), DIMENSION(x_min-2:x_max+2,y_min-2:y_max+2,z_min-2:z_max+2) :: pressure
  REAL(KIND=8), DIMENSION(x_min-2:x_max+2 ,y_min-2:y_max+2 ,z_min-2:z_max+2) :: viscosity
  REAL(KIND=8), DIMENSION(x_min-2:x_max+3 ,y_min-2:y_max+3 ,z_min-2:z_max+3) :: xvel0,yvel0,zvel0
  REAL(KIND=8), DIMENSION(x_min-2:x_max+3 ,y_min-2:y_max+3 ,z_min-2:z_max+3) :: xvel1,yvel1,zvel1
  REAL(KIND=8), DIMENSION(x_min-2:x_max+3,y_min-2:y_max+2,z_min-2:z_max+2) :: vol_flux_x,mass_flux_x
  REAL(KIND=8), DIMENSION(x_min-2:x_max+2,y_min-2:y_max+3,z_min-2:z_max+2) :: vol_flux_y,mass_flux_y
  REAL(KIND=8), DIMENSION(x_min-2:x_max+2,y_min-2:y_max+2,z_min-2:z_max+3) :: vol_flux_z,mass_flux_z
  REAL(KIND=8), DIMENSION(x_min-2:x_max+2,y_min-2:y_max+2,z_min-2:z_max+2) :: volume
  REAL(KIND=8), DIMENSION(x_min-2:x_max+3) :: vertexx
  REAL(KIND=8), DIMENSION(x_min-2:x_max+3) :: vertexdx
  REAL(KIND=8), DIMENSION(y_min-2:y_max+3) :: vertexy
  REAL(KIND=8), DIMENSION(y_min-2:y_max+3) :: vertexdy
  REAL(KIND=8), DIMENSION(z_min-2:z_max+3) :: vertexz
  REAL(KIND=8), DIMENSION(z_min-2:z_max+3) :: vertexdz
  REAL(KIND=8), DIMENSION(x_min-2:x_max+2) :: cellx
  REAL(KIND=8), DIMENSION(x_min-2:x_max+2) :: celldx
  REAL(KIND=8), DIMENSION(y_min-2:y_max+2) :: celly
  REAL(KIND=8), DIMENSION(y_min-2:y_max+2) :: celldy
  REAL(KIND=8), DIMENSION(z_min-2:z_max+2) :: cellz
  REAL(KIND=8), DIMENSION(z_min-2:z_max+2) :: celldz
  REAL(KIND=8), DIMENSION(x_min-2:x_max+3 ,y_min-2:y_max+2 ,z_min-2:z_max+2) :: xarea
  REAL(KIND=8), DIMENSION(x_min-2:x_max+2 ,y_min-2:y_max+3 ,z_min-2:z_max+2) :: yarea
  REAL(KIND=8), DIMENSION(x_min-2:x_max+2 ,y_min-2:y_max+2 ,z_min-2:z_max+3) :: zarea
  REAL(KIND=8) :: left_snd_buffer(:),left_rcv_buffer(:),right_snd_buffer(:),right_rcv_buffer(:)
  REAL(KIND=8) :: bottom_snd_buffer(:),bottom_rcv_buffer(:),top_snd_buffer(:),top_rcv_buffer(:)
  REAL(KIND=8) :: back_snd_buffer(:),back_rcv_buffer(:)
  REAL(KIND=8) :: front_snd_buffer(:),front_rcv_buffer(:)

  INTEGER :: fields(NUM_FIELDS)
  LOGICAL :: profiler_off

!$ACC DATA &
!$ACC COPY(density0) &
!$ACC COPY(density1) &
!$ACC COPY(energy0) &
!$ACC COPY(energy1) &
!$ACC COPY(pressure) &
!$ACC COPY(soundspeed) &
!$ACC COPY(viscosity) &
!$ACC COPY(xvel0) &
!$ACC COPY(yvel0) &
!$ACC COPY(zvel0) &
!$ACC COPY(xvel1) &
!$ACC COPY(yvel1) &
!$ACC COPY(zvel1) &
!$ACC COPY(vol_flux_x) &
!$ACC COPY(vol_flux_y) &
!$ACC COPY(vol_flux_z) &
!$ACC COPY(mass_flux_x) &
!$ACC COPY(mass_flux_y) &
!$ACC COPY(mass_flux_z) &
!$ACC COPY(volume) &
!$ACC COPY(cellx) &
!$ACC COPY(celly) &
!$ACC COPY(cellz) &
!$ACC COPY(celldx) &
!$ACC COPY(celldy) &
!$ACC COPY(celldz) &
!$ACC COPY(vertexx) &
!$ACC COPY(vertexdx) &
!$ACC COPY(vertexy) &
!$ACC COPY(vertexdy) &
!$ACC COPY(vertexz) &
!$ACC COPY(vertexdz) &
!$ACC COPY(xarea) &
!$ACC COPY(yarea) &
!$ACC COPY(zarea) &
!$ACC COPY(left_snd_buffer) &
!$ACC COPY(left_rcv_buffer) &
!$ACC COPY(right_snd_buffer) &
!$ACC COPY(right_rcv_buffer) &
!$ACC COPY(bottom_snd_buffer) &
!$ACC COPY(bottom_rcv_buffer) &
!$ACC COPY(top_snd_buffer) &
!$ACC COPY(top_rcv_buffer) &
!$ACC COPY(back_snd_buffer) &
!$ACC COPY(back_rcv_buffer) &
!$ACC COPY(front_snd_buffer) &
!$ACC COPY(front_rcv_buffer)

  ! Do no profile the start up costs otherwise the total times will not add up
  ! at the end
  profiler_off=profiler_on
  profiler_on=.FALSE.

  CALL initialise_chunk(c)

  IF(parallel%boss)THEN
     WRITE(g_out,*) 'Generating chunks'
  ENDIF

  CALL generate_chunk(c)

  advect_x=.TRUE.

  CALL clover_barrier

  CALL ideal_gas(c,.FALSE.)

  ! Prime all halo data for the first step
  fields=0
  fields(FIELD_DENSITY0)=1
  fields(FIELD_ENERGY0)=1
  fields(FIELD_PRESSURE)=1
  fields(FIELD_VISCOSITY)=1
  fields(FIELD_DENSITY1)=1
  fields(FIELD_ENERGY1)=1
  fields(FIELD_XVEL0)=1
  fields(FIELD_YVEL0)=1
  fields(FIELD_ZVEL0)=1
  fields(FIELD_XVEL1)=1
  fields(FIELD_YVEL1)=1
  fields(FIELD_ZVEL1)=1

  CALL update_halo(c,fields,2)

  IF(parallel%boss)THEN
     WRITE(g_out,*)
     WRITE(g_out,*) 'Problem initialised and generated'
  ENDIF

  CALL field_summary(c)

  IF(visit_frequency.NE.0) CALL visit(c)

!$ACC END DATA

  CALL clover_barrier

  profiler_on=profiler_off

END SUBROUTINE generate_on_device

END MODULE generate_on_device_module

SUBROUTINE start

  USE clover_module
  USE parse_module
  USE update_halo_module
  USE ideal_gas_module
  USE build_field_module
  USE generate_on_device_module
  USE data_module

  IMPLICIT NONE

  INTEGER :: c

  INTEGER :: x_cells,y_cells,z_cells
  INTEGER, ALLOCATABLE :: right(:),left(:),top(:),bottom(:),back(:),front(:)

  INTEGER :: fields(NUM_FIELDS) !, chunk_task_responsible_for 

  LOGICAL :: profiler_off

  IF(parallel%boss)THEN
     WRITE(g_out,*) 'Setting up initial geometry'
     WRITE(g_out,*)
  ENDIF

  time  = 0.0
  step  = 0
  dtold = dtinit
  dt    = dtinit

  CALL clover_barrier

  CALL clover_get_num_chunks(number_of_chunks)
  ALLOCATE(chunks(1:number_of_chunks))

  ALLOCATE(left(1:number_of_chunks))
  ALLOCATE(right(1:number_of_chunks))
  ALLOCATE(bottom(1:number_of_chunks))
  ALLOCATE(top(1:number_of_chunks))
  ALLOCATE(back(1:number_of_chunks))
  ALLOCATE(front(1:number_of_chunks))

  CALL clover_decompose(grid%x_cells,grid%y_cells,grid%z_cells,left,right,bottom,top,back,front)

  DO c=1,number_of_chunks
      
    ! Needs changing so there can be more than 1 chunk per task
    chunks(c)%task = c-1

    !chunk_task_responsible_for = parallel%task+1

    x_cells = right(c) -left(c)  +1
    y_cells = top(c)   -bottom(c)+1
    z_cells = front(c) -back(c)  +1
      
    IF(chunks(c)%task.EQ.parallel%task)THEN
      CALL build_field(c,x_cells,y_cells,z_cells)
    ENDIF
    chunks(c)%field%left    = left(c)
    chunks(c)%field%bottom  = bottom(c)
    chunks(c)%field%right   = right(c)
    chunks(c)%field%top     = top(c)
    chunks(c)%field%back    = back(c)
    chunks(c)%field%front   = front(c)
    chunks(c)%field%left_boundary   = 1
    chunks(c)%field%bottom_boundary = 1
    chunks(c)%field%back_boundary   = 1
    chunks(c)%field%right_boundary  = grid%x_cells
    chunks(c)%field%top_boundary    = grid%y_cells
    chunks(c)%field%front_boundary  = grid%z_cells
    chunks(c)%field%x_min = 1
    chunks(c)%field%y_min = 1
    chunks(c)%field%z_min = 1
    chunks(c)%field%x_max = right(c)-left(c)+1
    chunks(c)%field%y_max = top(c)-bottom(c)+1
    chunks(c)%field%z_max = front(c)-back(c)+1

  ENDDO

  DEALLOCATE(left,right,bottom,top,back,front)

  CALL clover_barrier

  DO c=1,number_of_chunks
    IF(chunks(c)%task.EQ.parallel%task)THEN
      CALL clover_allocate_buffers(c)
    ENDIF
  ENDDO

 CALL generate_on_device( parallel%task+1,                           &
			  chunks(parallel%task+1)%field%x_min, &
                          chunks(parallel%task+1)%field%x_max, &
                          chunks(parallel%task+1)%field%y_min, &
                          chunks(parallel%task+1)%field%y_max, &
                          chunks(parallel%task+1)%field%z_min, &
                          chunks(parallel%task+1)%field%z_max, &
                          chunks(parallel%task+1)%field%density0, &
                          chunks(parallel%task+1)%field%density1, &
                          chunks(parallel%task+1)%field%energy0, &
                          chunks(parallel%task+1)%field%energy1, &
                          chunks(parallel%task+1)%field%pressure, &
                          chunks(parallel%task+1)%field%soundspeed, &
                          chunks(parallel%task+1)%field%viscosity, &
                          chunks(parallel%task+1)%field%xvel0, &
                          chunks(parallel%task+1)%field%yvel0, &
                          chunks(parallel%task+1)%field%zvel0, &
                          chunks(parallel%task+1)%field%xvel1, &
                          chunks(parallel%task+1)%field%yvel1, &
                          chunks(parallel%task+1)%field%zvel1, &
                          chunks(parallel%task+1)%field%vol_flux_x, &
                          chunks(parallel%task+1)%field%vol_flux_y, &
                          chunks(parallel%task+1)%field%vol_flux_z, &
                          chunks(parallel%task+1)%field%mass_flux_x, &
                          chunks(parallel%task+1)%field%mass_flux_y, &
                          chunks(parallel%task+1)%field%mass_flux_z, &
                          chunks(parallel%task+1)%field%volume, &
                          chunks(parallel%task+1)%field%cellx, &
                          chunks(parallel%task+1)%field%celly, &
                          chunks(parallel%task+1)%field%cellz, &
                          chunks(parallel%task+1)%field%celldx, &
                          chunks(parallel%task+1)%field%celldy, &
                          chunks(parallel%task+1)%field%celldz, &
                          chunks(parallel%task+1)%field%vertexx, &
                          chunks(parallel%task+1)%field%vertexdx, &
                          chunks(parallel%task+1)%field%vertexy, &
                          chunks(parallel%task+1)%field%vertexdy, &
                          chunks(parallel%task+1)%field%vertexz, &
                          chunks(parallel%task+1)%field%vertexdz, &
                          chunks(parallel%task+1)%field%xarea, &
                          chunks(parallel%task+1)%field%yarea, &
                          chunks(parallel%task+1)%field%zarea, &
                          chunks(parallel%task+1)%left_snd_buffer, &
                          chunks(parallel%task+1)%left_rcv_buffer, &
                          chunks(parallel%task+1)%right_snd_buffer, &
                          chunks(parallel%task+1)%right_rcv_buffer, &
                          chunks(parallel%task+1)%bottom_snd_buffer, &
                          chunks(parallel%task+1)%bottom_rcv_buffer, &
                          chunks(parallel%task+1)%top_snd_buffer, &
                          chunks(parallel%task+1)%top_rcv_buffer, &
                          chunks(parallel%task+1)%back_snd_buffer, &
                          chunks(parallel%task+1)%back_rcv_buffer, &
                          chunks(parallel%task+1)%front_snd_buffer, &
                          chunks(parallel%task+1)%front_rcv_buffer)

END SUBROUTINE start


